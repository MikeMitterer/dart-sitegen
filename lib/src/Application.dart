part of sitegen;

class Application {
    final Logger _logger = new Logger("sitegen.Application");

    /// Commandline options
    final Options options;

    /// {timerForPageRefresh} waits 500ms before refreshing the page
    /// If there are more PageRefresh-Requests withing 500ms only the last refresh will be made
    Timer timerForPageRefresh = null;

    /// {timerWatchCss} waits 500ms before it calls it's watch-functions.
    /// If there are more watch-events within 500ms only the last event counts
    Timer timerWatchCss = null;

    /// {timerWatch} waits 500ms until all watched folders and files updated
    Timer timerWatch = null;

    Application() : options = new Options();

    Future run(final List<String> args) async {

        try {
            final CommandManager cm = await CommandManager.getInstance();
            final ArgResults argResults = options.parse(args);
            final Config config = new Config(argResults, cm);

            _configLogging(config.loglevel);

            try {
                _testPreconditions(cm);

            } catch(error) {
                stderr.writeln(error.toString());
                return 1;
            }

            if (argResults.wasParsed(Options._ARG_HELP) || (config.dirstoscan.length == 0 && args.length == 0)) {
                options.showUsage();
                return 0;
            }

            if (argResults.wasParsed(Options._ARG_SETTINGS)) {
                config.printSettings();
                return 0;
            }

            if (argResults.wasParsed(Options._ARG_SITE_KEYS)) {
                config.printSiteKeys();
                return 0;
            }

            bool foundOptionToWorkWith = false;

            if (argResults.wasParsed(Options._ARG_INIT)) {
                foundOptionToWorkWith = true;
                final Init init = new Init();
                init.createDirs(config).then((_) => init.createFiles(config));
                return 0;
            }


            if (argResults.wasParsed(Options._ARG_GENERATE)) {
                foundOptionToWorkWith = true;
                new Generator().generate(config);
            }

            if (argResults.wasParsed(Options._ARG_GENERATE_CSS)) {
                foundOptionToWorkWith = true;
                _compileSCSSFile(config.outputfolder, config);
            }

            if (argResults.wasParsed(Options._ARG_WATCH) || argResults.wasParsed(Options._ARG_WATCH_AND_SERVE)) {
                foundOptionToWorkWith = true;
                if (_isFolderAvailable(config.contentfolder) && _isFolderAvailable(config.templatefolder)) {
                    watch(config.contentfolder, config);
                    watch(config.templatefolder, config);

                    if(_isFolderAvailable(config.datafolder)) {
                        watch(config.datafolder, config);
                    }

                    if(_isFolderAvailable(config.partialsfolder)) {
                        watch(config.partialsfolder, config);
                    }

                    if(_isFolderAvailable(config.assetsfolder)) {
                        watch(config.assetsfolder, config);
                    }

                    new Generator().generate(config);
                }
                watchScss(config.outputfolder, config);
                // watchToRefresh(config.outputfolder, config);

                watchAdditionalFolderScss(config.watchfolder1,config.outputfolder, config);
                watchAdditionalFolderScss(config.watchfolder2,config.outputfolder, config);
                watchAdditionalFolderScss(config.watchfolder3,config.outputfolder, config);
            }

            if (argResults.wasParsed(Options._ARG_SERVE) || argResults.wasParsed(Options._ARG_WATCH_AND_SERVE)) {
                foundOptionToWorkWith = true;

                serve(config);
            }

            if (!foundOptionToWorkWith) {
                options.showUsage();
            }
        }

        on FormatException
        catch (error) {
            _logger.shout(error);
            options.showUsage();
            return 1;
        }

        return 0;
    }

    void serve(final Config config) {
        Validate.notBlank(config.ip);
        Validate.notBlank(config.docroot);
        Validate.notBlank(config.port);

        final String ip = config.ip;
        final String port = config.port;
        final String MY_HTTP_ROOT_PATH = config.docroot; //Platform.script.resolve(folder).toFilePath();

        VirtualDirectory virtDir;
        void _directoryHandler(final Directory dir,final HttpRequest request) {
            _logger.info(dir);
            var indexUri = new Uri.file(dir.path).resolve('index.html');
            virtDir.serveFile(new File(indexUri.toFilePath()), request);
        }

        virtDir = new VirtualDirectory(MY_HTTP_ROOT_PATH)
            ..allowDirectoryListing = true
            ..followLinks = true
            ..jailRoot = false
        ;
        virtDir.directoryHandler = _directoryHandler;

        final Packages packages = new Packages();

        // if hasPackages is false then we are not in a Dart-Project
        final bool hasPackages = packages.hasPackages;

        Future<HttpServer> connect;
        if(config.usesecureconnection) {
            final SecurityContext context = new SecurityContext();
            context.useCertificateChain(config.certfile);
            context.usePrivateKey(config.keyfile);
            connect = HttpServer.bindSecure(ip,int.parse(port),context);
            _logger.info('Using a secure connection on $ip - Scheme should be https!');

        } else {
            connect = HttpServer.bind(ip, int.parse(port));
        }

        runZoned(() {
            //HttpServer.bindSecure(ip,int.parse(port),context)
            //HttpServer.bind(ip, int.parse(port))
            connect.then( (final HttpServer server) {
                _logger.info('Server running $ip on port: $port, $MY_HTTP_ROOT_PATH');
                server.listen( (final HttpRequest request) {
                    if(request.uri.path.startsWith("/packages") && hasPackages) {
                        final List<String> parts = request.uri.path.split(new RegExp(r"(?:/|\\)"));
                        final String path = parts.sublist(3).join("/");
                        final String packageName = parts[2];

                        final Package package = packages.resolvePackageUri(
                            Uri.parse("package:${packageName}")
                        );
                        final String rewritten = "${package.lib.path}/$path".replaceFirst(new RegExp(r"^.*pub\.dartlang\.org/"),"package:");

                        _logger.info("${request.connectionInfo.remoteAddress.address}:${request.connectionInfo.localPort} - ${request.method} [Rewritten] ${rewritten}");
                        virtDir.serveFile(new File("${package.lib.path}/$path"),request);

                    } else {
                        _logger.info("${request.connectionInfo.remoteAddress.address}:${request.connectionInfo.localPort} - ${request.method} ${request.uri}");
                        virtDir.serveRequest(request);
                    }
                });
            });
        },
        onError: (e, stackTrace) => _logger.severe('Oh noes! $e $stackTrace'));
    }

    void watch(final String folder, final Config config) {
        Validate.notBlank(folder);
        Validate.notNull(config);

        _logger.info('Observing (watch) $folder...');

        final Directory srcDir = new Directory(folder);

        srcDir.watch(recursive: true).where((final file) => (!file.path.contains("packages"))).listen((final FileSystemEvent event) {
            _logger.info(event.toString());
            if(timerWatch == null) {
                timerWatch = new Timer(new Duration(milliseconds: 1000), () {
                    new Generator().generate(config);
                    timerWatch = null;
                });
            }
        });
    }

    void watchScss(final String folder, final Config config) {
        Validate.notBlank(folder);
        Validate.notNull(config);

        _logger.fine('Observing $folder (SCSS)... ');
        final Directory dir = new Directory(folder);
        final List<File> scssFiles = _listSCSSFilesIn(dir);

        if (scssFiles.length == 0) {
            _logger.info("No SCSS files found");
            return;
        }

        _compileSCSSFile(folder,config);

        try {

            scssFiles.forEach((final File file) {
                _logger.info("Observing: (watchScss) ${file.path}");

                file.watch(events: FileSystemEvent.MODIFY).listen((final FileSystemEvent event) {
                    _logger.fine(event.toString());
                    //_logger.info("Scss: ${scssFile}, CSS: ${cssFile}");

                    if(timerWatchCss == null) {
                        timerWatchCss = new Timer(new Duration(milliseconds: 500), () {

                            _compileSCSSFile(folder,config);
                            timerWatchCss = null;
                        });
                    }

                });
            });

        }
        on StateError {
            _logger.info("Found no SCSS without a _ at the beginning...");
        }
    }

    void watchAdditionalFolderScss(final String additionalWatchFolder, final String cssFolder, final Config config) {
        Validate.notBlank(cssFolder);
        Validate.notNull(config);

        if(additionalWatchFolder.isEmpty) {
            return;
        }

        _logger.fine('Observing $cssFolder (SCSS)... ');

        final Directory dirToCheck = new Directory(additionalWatchFolder);
        final Directory dir = new Directory(cssFolder);
        final List<File> scssFiles = _listSCSSFilesIn(dir);

        if (scssFiles.length == 0) {
            _logger.info("No SCSS files found");
            return;
        }

        _compileSCSSFile(cssFolder,config);

        try {

            _logger.info("Observing: (watchAdditionalFolderScss) ${dirToCheck.path}");

            dirToCheck.watch(events: FileSystemEvent.MODIFY).listen((final FileSystemEvent event) {
                _logger.fine(event.toString());
                //_logger.info("Scss: ${scssFile}, CSS: ${cssFile}");

                if(timerWatchCss == null) {
                    timerWatchCss = new Timer(new Duration(milliseconds: 500), () {

                        _compileSCSSFile(cssFolder,config);
                        timerWatchCss = null;
                    });
                }

            });

        }
        on StateError {
            _logger.info("Found no SCSS without a _ at the beginning...");
        }
    }

    /*
    void watchToRefresh(final String folder, final Config config) {
        Validate.notBlank(folder);
        Validate.notNull(config);

        _logger.fine('Observing: (watchToRefresh) $folder...');

        void _schedulePageRefresh() {
            if(timerForPageRefresh == null) {
                timerForPageRefresh = new Timer(new Duration(milliseconds: 500), () {
                    _refreshPage(config);
                    timerForPageRefresh = null;
                });
            }
        }

        final File srcDir = new File(folder);
        srcDir.watch(recursive: true).listen((final FileSystemEvent event) {
            _logger.fine(event.toString());
            _schedulePageRefresh();
        });
    }
    */

    // -- private -------------------------------------------------------------

    void _testPreconditions(final CommandManager cm) {
        if((cm.containsKey(CommandManager.SASS) || cm.containsKey(CommandManager.SASSC))
            && cm.containsKey(CommandManager.AUTOPREFIXER)) {
            return;
        }
        throw "Please install SASS (${CommandManager.SASS} | ${CommandManager.SASSC}) "
            "and AutoPrefixer (${CommandManager.AUTOPREFIXER})";
    }

    void _compileSCSSFile(final String folder, final Config config) {
        Validate.notBlank(folder);
        Validate.notNull(config);

        _logger.fine('Observing: (_compileSCSSFile) $folder (SCSS)... ');
        final Directory dir = new Directory(folder);
        final List<File> scssFiles = _listSCSSFilesIn(dir);

        if (scssFiles.length == 0) {
            _logger.info("No SCSS files found");
            return;
        }

        // mainScssFile is the one not starting with a _ (underscore)
        File _mainScssFile(final List<File> scssFiles) {
            final File mainScss = scssFiles.firstWhere((final File file) {
                final String pureFilename = path.basename(file.path);
                return pureFilename.startsWith(new RegExp(r"[a-z]", caseSensitive: false));
            });
            return mainScss;
        }

        final File mainScss = _mainScssFile(scssFiles);

        final String scssFile = mainScss.path;
        final String cssFile = "${path.withoutExtension(scssFile)}.css";

        _logger.info("Main SCSS: $scssFile");
        _compileScss(scssFile, cssFile,config);
        _autoPrefixer(cssFile,config);
    }

    /*
    REMINDER!

    /**
     * Weitere Infos:
     *      https://github.com/guard/guard-livereload
     *      https://github.com/nitoyon/livereloadx
     *      http://goo.gl/M1L4kf
     *
     *      WebSocket / ChromeExtension: http://goo.gl/unsnXc
     */
    Future _refreshPage(final Config config) async {
        Validate.notNull(config);

        if(!Platform.isMacOS) {
            _logger.info("Page refresh is only supported on Mac");
            return;
        }

        final String content = """
                tell application "${config.browser}"
                    set windowList to every window
                    repeat with aWindow in windowList
                        set tabList to every tab of aWindow
                        repeat with atab in tabList
                            if (URL of atab contains "localhost") then
                                tell atab to reload
                            end if
                        end repeat
                    end repeat
                end tell
        """;

        final String version = "1.0";
        final String executable = "osascript";
        final String scriptName = "refresh${config.browser}";
        final String scriptExtension = "applescript";

        final Directory contenfolder = new Directory(config.configfolder);
        if (!await contenfolder.exists()) {
            await contenfolder.create();
        }

        final File script = new File("${contenfolder.path}/$scriptName-${version}.$scriptExtension");
        if (!await script.exists()) {
            contenfolder.listSync().forEach((final entity) {
                _logger.info("Entity: ${entity.path}");
                if (entity is File && path.basename(entity.path).startsWith(scriptName)) {
                    final File oldScript = new File(entity.path);
                    oldScript.delete();
                }
            });
            await script.writeAsString(content.trim());
            _logger.info("${script.path} created...");
        }

        final ProcessResult resultOsascript = await Process.run(executable, [ script.path ]);
        if (resultOsascript.exitCode != 0) {
            _logger.severe("$executable faild with: ${(resultOsascript.stderr as String).trim()}!");
            _vickiSay("$executable failed",config);
            return;
        }

        _logger.info("$executable ${script.path} successful!");
    }
    */

    bool _isFolderAvailable(final String folder) {
        Validate.notBlank(folder);
        final Directory dir = new Directory(folder);
        return dir.existsSync();
    }

    void _compileScss(final String source, final String target, final Config config) {
        Validate.notBlank(source);
        Validate.notBlank(target);
        Validate.notNull(config);

        if(!config.usesass) {
            _logger.info("Sass was disabled - so your SCSS won't be compiled to CSS!");
            return;
        }

        final String compiler = config.sasscompiler;
        final Map<String,String> environment = new Map<String,String>();

        if(config.sasspath.isNotEmpty) {

            // only sass supports SASS_PATH (not sassc)
            if(!compiler.endsWith("c")) {
                environment["SASS_PATH"] = config.sasspath;
                _logger.info("Using SASS_PATH: ${config.sasspath}");
            } else {
                _logger.warning("SASS_PATH ist not supported by your compiler!");
            }

        }

        _logger.info("Compiling $source -> $target");
        final ProcessResult result = Process.runSync(compiler, [ source, target ], environment: environment);
        if (result.exitCode != 0) {
            _logger.info("sassc faild with: ${(result.stderr as String).trim()}!");
            _vickiSay("got a sassc error",config);
            return;
        }
        _logger.info("Done!");
    }

    void _autoPrefixer(final String cssFile, final Config config) {
        Validate.notBlank(cssFile);
        Validate.notNull(config);

        if(!config.useautoprefixer) {
            _logger.info("Autoprefixing was disabled - so your CSS won't be prefixed!");
            return;
        }

        _logger.info("Autoprefixing $cssFile");
        final ProcessResult result = Process.runSync("autoprefixer-cli", [ cssFile ]);
        if (result.exitCode != 0) {
            _logger.info("prefixer faild with: ${(result.stderr as String).trim()}!");
            _vickiSay("got a prefixer error",config);
            return;
        }
        _logger.info("Done!");
    }

    List<File> _listSCSSFilesIn(final Directory dir) {
        Validate.notNull(dir);
        return dir.listSync(recursive: true).where((final file) {
            return file is File && file.path.endsWith(".scss") && !file.path.contains("packages");
        })
            .map((final FileSystemEntity entity) => entity as File)
            .toList();
    }

    void _vickiSay(final String sentence,final Config config) {
        Validate.notBlank(sentence);

        if(config.talktome == false) {
            _logger.severe("Vicki wants to say: '${sentence}'");
            return;
        }

        final ProcessResult result = Process.runSync("say", [ '-r', '200', sentence.replaceFirst("wsk_", "") ]);
        if (result.exitCode != 0) {
            _logger.severe("run faild with: ${(result.stderr as String).trim()}!");
        }
    }

    void _configLogging(final String loglevel) {
        Validate.notBlank(loglevel);

        hierarchicalLoggingEnabled = false; // set this to true - its part of Logging SDK

        // now control the logging.
        // Turn off all logging first
        switch (loglevel) {
            case "fine":
            case "debug":
                Logger.root.level = Level.FINE;
                break;

            case "warning":
                Logger.root.level = Level.SEVERE;
                break;

            default:
                Logger.root.level = Level.INFO;
        }

        Logger.root.onRecord.listen(new LogPrintHandler(transformer: transformerMessageOnly));
    }
}
