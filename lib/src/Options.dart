part of dartpad;

class Options {
    static const APPNAME                    = 'dartpad';

    static const _ARG_HELP                  = 'help';
    static const _ARG_LOGLEVEL              = 'loglevel';
    static const _ARG_SETTINGS              = 'settings';
    static const _ARG_GENERATE              = 'generate';

    final ArgParser _parser;

    Options() : _parser = Options._createParser();

    ArgResults parse(final List<String> args) {
        Validate.notNull(args);
        return _parser.parse(args);
    }

    void showUsage() {
        print("Usage: $APPNAME [options]");
        _parser.getUsage().split("\n").forEach((final String line) {
            print("    $line");
        });

        print("");
        print("Sample: (usual workflow)");
        print("");
        print("    'pub update' for every example:                      '$APPNAME -u'");
        print("    'sassc & autoprefix for scss-Files:                  '$APPNAME -a'");
        print("    'pub build' for every example:                       '$APPNAME -b'");
        print("    'Copy example/<sample>/build/web to build/example/:  '$APPNAME -c'");
        print("    'Rsyncs build/example to webserver:                  '$APPNAME -r --rsyncdest <usr>@<host>:<folder>/'");
        print("");
    }

    // -- private -------------------------------------------------------------

    static ArgParser _createParser() {
        final ArgParser parser = new ArgParser()

            ..addFlag(_ARG_SETTINGS,         abbr: 's', negatable: false, help: "Prints settings")
            ..addFlag(_ARG_HELP,             abbr: 'h', negatable: false, help: "Shows this message")
            ..addFlag(_ARG_GENERATE,         abbr: 'x', negatable: false, help: "Generate site")

            ..addOption(_ARG_LOGLEVEL,       abbr: 'v', help: "Sets the appropriate loglevel", allowed: ['info', 'debug', 'warning'])
        ;

        return parser;
    }
}
