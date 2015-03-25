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

            bool foundOptionToWorkWith = false;

            if(argResults.wasParsed(Options._ARG_GENERATE)) {
                foundOptionToWorkWith = true;
                new Generator().generate(config);
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

    // -- private -------------------------------------------------------------

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
