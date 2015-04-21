part of sitegen;

/**
 * Defines default-configurations.
 * Most of these configs can be overwritten by commandline args.
 */
class Config {
    final Logger _logger = new Logger("sitegen.Config");

    static const _CONF_CONTENT_DIR        = 'content_dir';
    static const _CONF_TEMPLATE_DIR       = 'template_dir';
    static const _CONF_OUTPUT_DIR         = 'output_dir';
    static const _CONF_DATA_DIR           = 'data_dir';
    static const _CONF_PARTIALS_DIR       = 'partials_dir';
    static const _CONF_WORKSPACE_DIR      = 'workspace';
    static const _CONF_DATE_FORMAT        = 'date_format';
    static const _CONF_YAML_DELIMITER     = 'yaml_delimeter';
    static const _CONF_USE_MARKDOWN       = 'use_markdown';
    static const _CONF_DEFAULT_TEMPLATE   = 'default_template';
    static const _CONF_SITE_OPTIONS       = 'site_options';
    static const _CONF_SASS_COMPILER      = 'sasscompiler';
    static const _CONF_USE_SASS           = 'usesass';
    static const _CONF_USE_AUTOPREFIXER   = 'autoprefixer';
    static const _CONF_BROWSER            = 'browser';

    final ArgResults _argResults;
    final Map<String,dynamic> _settings = new Map<String,dynamic>();

    Config(this._argResults) {

        _settings[Options._ARG_LOGLEVEL]            = 'info';

        _settings[Config._CONF_CONTENT_DIR]         = 'html/_content';
        _settings[Config._CONF_TEMPLATE_DIR]        = 'html/_templates';
        _settings[Config._CONF_DATA_DIR]            = 'html/_data';
        _settings[Config._CONF_PARTIALS_DIR]        = 'html/_partials';
        _settings[Config._CONF_OUTPUT_DIR]          = 'web';
        _settings[Config._CONF_WORKSPACE_DIR]       = '.';
        _settings[Config._CONF_DATE_FORMAT]         = 'dd.MM.yyyy';
        _settings[Config._CONF_YAML_DELIMITER]      = '~~~';
        _settings[Config._CONF_USE_MARKDOWN]        = true;
        _settings[Config._CONF_DEFAULT_TEMPLATE]    = "default.html";
        _settings[Config._CONF_SASS_COMPILER]       = "sassc";
        _settings[Config._CONF_BROWSER]             = "Chromium";

        _settings[Config._CONF_SITE_OPTIONS]        = {};

        _settings[Options._ARG_PORT]                = "8080";

        _settings[Config._CONF_USE_SASS]            = true;
        _settings[Config._CONF_USE_AUTOPREFIXER]    = true;



        _overwriteSettingsWithConfigFile();
        _overwriteSettingsWithArgResults();
    }

    List<String> get dirstoscan => _argResults.rest;

    String get configfolder => ".sitegen";

    String get configfile => "site.yaml";

    String get loglevel => _settings[Options._ARG_LOGLEVEL];

    String get contentfolder => _settings[Config._CONF_CONTENT_DIR];

    String get templatefolder => _settings[Config._CONF_TEMPLATE_DIR];

    String get outputfolder => _settings[Config._CONF_OUTPUT_DIR];

    String get datafolder => _settings[Config._CONF_DATA_DIR];

    String get partialsfolder => _settings[Config._CONF_PARTIALS_DIR];

    String get workspace => _settings[Config._CONF_WORKSPACE_DIR];

    String get dateformat => _settings[Config._CONF_DATE_FORMAT];

    String get yamldelimeter => _settings[Config._CONF_YAML_DELIMITER];

    bool get usemarkdown => _settings[Config._CONF_USE_MARKDOWN];

    String get defaulttemplate => _settings[Config._CONF_DEFAULT_TEMPLATE];

    String get sasscompiler => _settings[Config._CONF_SASS_COMPILER];

    Map<String,String> get siteoptions => _settings[Config._CONF_SITE_OPTIONS];

    String get port => _settings[Options._ARG_PORT];

    bool get usesass => _settings[Config._CONF_USE_SASS];

    bool get useautoprefixer => _settings[Config._CONF_USE_AUTOPREFIXER];

    String get browser =>  _settings[Config._CONF_BROWSER];

    Map<String,String> get settings {
        final Map<String,String> settings = new Map<String,String>();

        settings["loglevel"]                                = loglevel;

        settings["Content folder"]                          = contentfolder;
        settings["Template folder"]                         = templatefolder;
        settings["Data folder"]                             = datafolder;
        settings["Partials folder"]                         = partialsfolder;

        settings["Default template"]                        = defaulttemplate;
        settings["Output folder"]                           = outputfolder;
        settings["Workspace"]                               = workspace;

        settings["Dateformat"]                              = dateformat;
        settings["YAML-Delimeter"]                          = yamldelimeter;

        settings["Use markdown"]                            = usemarkdown ? "yes" : "no";
        settings["Use SASS"]                                = usesass ? "yes" : "no";
        settings["Use Autoprefixer"]                        = useautoprefixer ? "yes" : "no";

        settings["Site options"]                            = siteoptions.toString();

        settings["Config folder"]                           = configfolder;
        settings["Config file"]                             = configfile;

        settings["SASS compiler"]                           = sasscompiler;
        settings["Browser"]                                 = browser;

        settings["Port"]                                    = port;

        if(dirstoscan.length > 0) {
            settings["Dirs to scan"]                        = dirstoscan.join(", ");
        }

        return settings;
    }


    void printSettings() {

        int getMaxKeyLength() {
            int length = 0;
            settings.keys.forEach((final String key) => length = max(length,key.length));
            return length;
        }

        final int maxKeyLeght = getMaxKeyLength();

        String prepareKey(final String key) {
            return "${key[0].toUpperCase()}${key.substring(1)}:".padRight(maxKeyLeght + 1);
        }

        print("Settings:");
        settings.forEach((final String key,final String value) {
            print("    ${prepareKey(key)} $value");
        });
    }

    // -- private -------------------------------------------------------------

    void _overwriteSettingsWithArgResults() {

        /// Makes sure that path does not end with a /
        String checkPath(final String arg) {
            String path = arg;
            if(path.endsWith("/")) {
                path = path.replaceFirst(new RegExp("/\$"),"");
            }
            return path;
        }

        if(_argResults.wasParsed(Options._ARG_LOGLEVEL)) {
            _settings[Options._ARG_LOGLEVEL] = _argResults[Options._ARG_LOGLEVEL];
        }

        if(_argResults.wasParsed(Options._ARG_PORT)) {
            _settings[Options._ARG_PORT] = _argResults[Options._ARG_PORT];
        }

        if(_argResults.wasParsed(Options._ARG_USE_SASS)) {
            _settings[Config._CONF_USE_SASS] = _argResults[Options._ARG_USE_SASS];
        }

        if(_argResults.wasParsed(Options._ARG_USE_AUTOPREFIXER)) {
            _settings[Config._CONF_USE_AUTOPREFIXER] = _argResults[Options._ARG_USE_AUTOPREFIXER];
        }

    }

    void _overwriteSettingsWithConfigFile() {
        final File file = new File("${configfolder}/${configfile}");
        if(!file.existsSync()) {
            return;
        }
        final yaml.YamlMap map = yaml.loadYaml(file.readAsStringSync());
        _settings.keys.forEach((final String key) {
            if(map != null && map.containsKey(key)) {
                _settings[key] = map[key];
                //print("Found $key in $configfile: ${map[key]}");
            }
        });
    }
}