part of sitegen;

/// Commandline options
class Options {
    static const APPNAME                    = 'sitegen';

    static const _ARG_HELP                  = 'help';
    static const _ARG_LOGLEVEL              = 'loglevel';
    static const _ARG_SETTINGS              = 'settings';
    static const _ARG_SITE_KEYS             = 'keys';
    static const _ARG_GENERATE              = 'generate';
    static const _ARG_GENERATE_CSS          = 'generatecss';
    static const _ARG_SERVE                 = 'serve';
    static const _ARG_IP                    = 'ip';
    static const _ARG_PORT                  = 'port';
    static const _ARG_WATCH                 = 'watch';
    static const _ARG_WATCH_AND_SERVE       = 'watchandserve';
    static const _ARG_INIT                  = 'init';
    static const _ARG_DOCROOT               = 'docroot';

    static const _ARG_USE_SASS              = 'usesass';
    static const _ARG_USE_AUTOPREFIXER      = 'useapfx';
    static const _ARG_USE_SECURE_CONNECTION = 'usesec';
    static const _ARG_TALK_TO_ME            = 'talktome';

    final ArgParser _parser;

    Options() : _parser = Options._createParser();

    ArgResults parse(final List<String> args) {
        Validate.notNull(args);
        return _parser.parse(args);
    }

    void showUsage() {
        print("Usage: $APPNAME [options]");
        _parser.usage.split("\n").forEach((final String line) {
            print("    $line");
        });

        print("");
        print("Sample:");
        print("");
        print("    'Generates all basic files and folders:                '$APPNAME -i'");
        print("    'Observes the default dirs and serves the web-folder:  '$APPNAME -w --serve'");
        print("    'Observes the default dirs and serves the web-folder:  '$APPNAME -x'");
        print("    'Serve your site via https:                            '$APPNAME -x --usesec'");
        print("    'Generates the static site in your 'web-folder':       '$APPNAME -g'");
        print("");
    }

    // -- private -------------------------------------------------------------

    static ArgParser _createParser() {
        final ArgParser parser = new ArgParser()

            ..addFlag(_ARG_SETTINGS,         abbr: 's', negatable: false, help: "Prints settings")

            ..addFlag(_ARG_SITE_KEYS,        abbr: 'k', negatable: false, help: "Shows keys for site.yaml")

            ..addFlag(_ARG_HELP,             abbr: 'h', negatable: false, help: "Shows this message")

            ..addFlag(_ARG_GENERATE,         abbr: 'g', negatable: false, help: "Generate site")

            ..addFlag(_ARG_GENERATE_CSS,     abbr: 'c', negatable: false, help: "Generate CSS (compile SCSS2CSS)")

            ..addFlag(_ARG_WATCH,            abbr: 'w', negatable: false, help: "Observes SRC-dir")

            ..addFlag(_ARG_WATCH_AND_SERVE,  abbr: 'x', negatable: false, help: "Shortcut to watch and serve")

            ..addFlag(_ARG_INIT,             abbr: 'i', negatable: false, help: "Initializes your site\n(not combinable with other options)")

            ..addFlag(_ARG_SERVE,                       negatable: false, help: "Serves your site")

            ..addFlag(_ARG_USE_SASS,                    negatable: true, help: "Enables / disables SASS to CSS compiler", defaultsTo: true)

            ..addFlag(_ARG_USE_AUTOPREFIXER,            negatable: true, help: "Enables / disables Autoprefixer", defaultsTo: true)

            ..addFlag(_ARG_USE_SECURE_CONNECTION,       negatable: false, help: "Use secure connection", defaultsTo: false)

            ..addFlag(_ARG_TALK_TO_ME,                  negatable: true, help: "Enables / disables Speek-Output", defaultsTo: _runsOnOSX())

            ..addOption(_ARG_IP,                        help: "Sets the IP-Address to listen on", defaultsTo: "0.0.0.0")

            ..addOption(_ARG_PORT,                      help: "Sets the port to listen on")

            ..addOption(_ARG_DOCROOT,                   help: "Document root", defaultsTo: "web")

            ..addOption(_ARG_LOGLEVEL,       abbr: 'v', help: "Sets the appropriate loglevel", allowed: ['info', 'debug', 'warning'])
        ;

        return parser;
    }
}
