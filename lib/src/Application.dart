part of dartpad;

class Application {
    final Logger _logger = new Logger("dartpad.Application");

    final Options options;

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

            if(argResults.wasParsed(Options._ARG_SETTINGS)) {
                config.printSettings();
                return;
            }

            if(argResults.wasParsed(Options._ARG_TEST)) {
                _test(config);
                return;
            }

            bool foundOptionToWorkWith = false;

            if(argResults.wasParsed(Options._ARG_GENERATE)) {
                foundOptionToWorkWith = true;
                new Generator().generate(config);
            }

            if(argResults.wasParsed(Options._ARG_WATCH)) {
                foundOptionToWorkWith = true;
                new Generator().generate(config);
                watch(config.contentfolder,config);
                watchScss(config.outputfolder,config);
            }

            if(argResults.wasParsed(Options._ARG_SERVE)) {
                foundOptionToWorkWith = true;
                final String port = argResults[Options._ARG_PORT];
                serve(config.outputfolder,port);
            }

            if(!foundOptionToWorkWith) {
                options.showUsage();
            }
        }

        on FormatException
        catch (error) {
            _logger.shout(error);
            options.showUsage();
        }
    }

    void serve(final String folder,final String port) {
        Validate.notBlank(folder);
        Validate.notBlank(port);

        var staticFiles = new VirtualDirectory(folder)
            ..allowDirectoryListing = true;

        runZoned(() {
            HttpServer.bind('0.0.0.0', int.parse(port)).then( (final HttpServer server) {
                _logger.info('Server running on port: $port');
                server.listen(staticFiles.serveRequest);
            });
        },
        onError: (e, stackTrace) => _logger.severe('Oh noes! $e $stackTrace'));
    }

    void watch(final String folder,final Config config) {
        Validate.notBlank(folder);
        Validate.notNull(config);

        _logger.info('Observing $folder...');

        final List<StreamSubscription<FileSystemEvent>> watchers = new List();
        final File srcDir = new File(folder);
        srcDir.watch().listen((final FileSystemEvent event) {
            _logger.info(event.toString());
            new Generator().generate(config);
        });
    }

    void watchScss(final String folder,final Config config) {
        Validate.notBlank(folder);
        Validate.notNull(config);

        _logger.info('Observing $folder (SCSS)... ');
        final Directory dir = new Directory(folder);
        final List<File> scssFiles = _listSCSSFilesIn(dir);

        if(scssFiles.length == 0) {
            _logger.info("No SCSS files found");
            return;
        }

        scssFiles.forEach((final File file) {
            file.watch(events: FileSystemEvent.MODIFY).listen( (final FileSystemEvent event) {
                _logger.info(event.toString());

                final String scssFile = event.path;
                final String cssFile = "${path.withoutExtension(scssFile)}.css";

                _compileScss(scssFile,cssFile);
            });
        });
    }


    // -- private -------------------------------------------------------------

    _test(final Config config) {

        final ProcessResult result = Process.runSync("pwd", []);
        if(result.exitCode != 0) {
            _logger.info("sassc faild with: ${(result.stderr as String).trim()}!");
            _vickiSay("got a sassc error");
            return;
        }
        _logger.info(result.stdout);
        _logger.info(Directory.current.path);

        //var file = new File(Platform.script.toFilePath());
        _logger.info("${Platform.script}");

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
        if(!contenfolder.existsSync()) {
            contenfolder.createSync();
        }

        final File script = new File("${contenfolder.path}/$scriptName-${version}.$scriptExtension");
        if(!script.existsSync()) {
            contenfolder.listSync().forEach( (final entity) {
                _logger.info("Entity: ${entity.path}");
                if(entity is File && path.basename(entity.path).startsWith(scriptName)) {
                    final File oldScript = new File(entity.path);
                    oldScript.deleteSync();
                }
            });
            script.writeAsStringSync(content.trim());
            _logger.info("${script.path} created...");
        }

        final ProcessResult resultOsascript = Process.runSync(executable, [ script.path ]);
        if(resultOsascript.exitCode != 0) {
            _logger.info("$executable faild with: ${(result.stderr as String).trim()}!");
            _vickiSay("$executable failed");
            return;
        }
        _logger.info("$executable ${script.path} successful!");
    }

    _compileScss(final String source,final String target) {
        Validate.notBlank(source);
        Validate.notBlank(target);

        _logger.info("Compiling $source -> $target");
        final ProcessResult result = Process.runSync("sassc", [ source, target ]);
        if(result.exitCode != 0) {
            _logger.info("sassc faild with: ${(result.stderr as String).trim()}!");
            _vickiSay("got a sassc error");
            return;
        }
        _logger.info("Done!");
    }

    List<File> _listSCSSFilesIn(final Directory dir) {
        Validate.notNull(dir);
        return dir.listSync(recursive: true).where( (final file) {
            return file is File && file.path.endsWith(".scss");
        }).toList();
    }

    void _vickiSay(final String sentence) {
        Validate.notBlank(sentence);

        final ProcessResult result = Process.runSync( "say", [ '-v', "Vicki",'-r', '200', sentence.replaceFirst("wsk_","") ]);
        if(result.exitCode != 0) {
            _logger.severe("run faild with: ${(result.stderr as String).trim()}!");
        }
    }

    void _configLogging(final String loglevel) {
        Validate.notBlank(loglevel);

        hierarchicalLoggingEnabled = false; // set this to true - its part of Logging SDK

        // now control the logging.
        // Turn off all logging first
        switch(loglevel) {
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
