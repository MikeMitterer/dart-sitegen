part of sitegen;

class Application {
    final Logger _logger = new Logger("sitegen.Application");

    final Options options;
    Timer timerForPageRefresh = null;

    Application() : options = new Options();

    void run(List<String> args) {

        try {
            final ArgResults argResults = options.parse(args);
            final Config config = new Config(argResults);

            _configLogging(config.loglevel);

            if (argResults.wasParsed(Options._ARG_HELP) || (config.dirstoscan.length == 0 && args.length == 0)) {
                options.showUsage();
                return;
            }

            if (argResults.wasParsed(Options._ARG_SETTINGS)) {
                config.printSettings();
                return;
            }

//            if (argResults.wasParsed(Options._ARG_TEST)) {
//                _testPWD(config.outputfolder);
//                _testPWD2();
//
//                return;
//            }

            bool foundOptionToWorkWith = false;

            if (argResults.wasParsed(Options._ARG_GENERATE)) {
                foundOptionToWorkWith = true;
                new Generator().generate(config);
            }

            if (argResults.wasParsed(Options._ARG_WATCH)) {
                foundOptionToWorkWith = true;
                if (_isFolderAvailable(config.contentfolder) && _isFolderAvailable(config.templatefolder)) {
                    watch(config.contentfolder, config);
                    watch(config.templatefolder, config);
                    new Generator().generate(config);
                }
                watchScss(config.outputfolder, config);
                watchToRefresh(config.outputfolder, config);
            }

            if (argResults.wasParsed(Options._ARG_SERVE)) {
                foundOptionToWorkWith = true;
                final String port = argResults[Options._ARG_PORT];
                serve(config.outputfolder, port);
            }

            if (!foundOptionToWorkWith) {
                options.showUsage();
            }
        }

        on FormatException
        catch (error) {
            _logger.shout(error);
            options.showUsage();
        }
    }

    void serve(final String folder, final String port) {
        Validate.notBlank(folder);
        Validate.notBlank(port);

        final String MY_HTTP_ROOT_PATH = folder; //Platform.script.resolve(folder).toFilePath();

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

        runZoned(() {
            HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, int.parse(port)).then( (final HttpServer server) {
                _logger.info('Server running on port: $port, $MY_HTTP_ROOT_PATH');
                server.listen( (final HttpRequest request) {
                    _logger.info("${request.connectionInfo.remoteAddress.address}:${request.connectionInfo.localPort} - ${request.method} ${request.uri}");
                    virtDir.serveRequest(request);
                });
            });
        },
        onError: (e, stackTrace) => _logger.severe('Oh noes! $e $stackTrace'));
    }

    void watch(final String folder, final Config config) {
        Validate.notBlank(folder);
        Validate.notNull(config);

        _logger.fine('Observing $folder...');

        final File srcDir = new File(folder);
        srcDir.watch(recursive: true).listen((final FileSystemEvent event) {
            _logger.fine(event.toString());
            new Generator().generate(config);
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

        File _mainScssFile(final List<File> scssFiles) {
            final File mainScss = scssFiles.firstWhere((final File file) {
                final String pureFilename = path.basename(file.path);
                return pureFilename.startsWith(new RegExp(r"[a-z]", caseSensitive: false));
            });
            return mainScss;
        }

        try {
            final File mainScss = _mainScssFile(scssFiles);

            final String scssFile = mainScss.path;
            final String cssFile = "${path.withoutExtension(scssFile)}.css";

            _logger.info("Main SCSS: $scssFile");
            _compileScss(config.sasscompiler,scssFile, cssFile);

            scssFiles.forEach((final File file) {
                _logger.info("Observing: ${file.path}");

                file.watch(events: FileSystemEvent.MODIFY).listen((final FileSystemEvent event) {
                    _logger.fine(event.toString());
                    //_logger.info("Scss: ${scssFile}, CSS: ${cssFile}");

                    _compileScss(config.sasscompiler, scssFile, cssFile);
                });
            });

        }
        on StateError catch (e) {
            _logger.info("Found no SCSS without a _ at the beginning...");
        }
    }

    void watchToRefresh(final String folder, final Config config) {
        Validate.notBlank(folder);
        Validate.notNull(config);

        _logger.fine('Observing $folder...');

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

    // -- private -------------------------------------------------------------

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

        // Nur zum testen!
        final ProcessResult result = await Process.run("pwd", []);
        if (result.exitCode != 0) {
            _logger.info("sassc faild with: ${(result.stderr as String).trim()}!");
            _vickiSay("got a sassc error");
            return;
        }
        _logger.fine(result.stdout.trim());

        final String content = """
                tell application "Chromium"
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
        final String scriptName = "refreshChromium";
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
            _vickiSay("$executable failed");
            return;
        }

        _logger.info("$executable ${script.path} successful!");
    }

    bool _isFolderAvailable(final String folder) {
        Validate.notBlank(folder);
        final Directory dir = new Directory(folder);
        return dir.existsSync();
    }

    Future _compileScss(final String compiler, final String source, final String target) async {
        Validate.notBlank(compiler);
        Validate.notBlank(source);
        Validate.notBlank(target);

        _logger.info("Compiling $source -> $target");
        final ProcessResult result = await Process.run(compiler, [ source, target ]);
        if (result.exitCode != 0) {
            _logger.info("sassc faild with: ${(result.stderr as String).trim()}!");
            _vickiSay("got a sassc error");
            return;
        }
        _logger.info("Done!");
    }

    List<File> _listSCSSFilesIn(final Directory dir) {
        Validate.notNull(dir);
        return dir.listSync(recursive: true).where((final file) {
            return file is File && file.path.endsWith(".scss") && !file.path.contains("packages");
        }).toList();
    }

    void _vickiSay(final String sentence) {
        Validate.notBlank(sentence);

        final ProcessResult result = Process.runSync("say", [ '-v', "Vicki", '-r', '200', sentence.replaceFirst("wsk_", "") ]);
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

        Logger.root.onRecord.listen(new LogPrintHandler(messageFormat: "%m"));
    }
}
