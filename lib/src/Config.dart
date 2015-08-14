part of sitegen;

/**
 * Defines default-configurations.
 * Most of these configs can be overwritten by commandline args.
 */
class Config {
    final Logger _logger = new Logger("sitegen.Config");

    static const String _CONFIG_FOLDER     = ".sitegen";

    static const _CONF_CONTENT_DIR        = 'content_dir';
    static const _CONF_TEMPLATE_DIR       = 'template_dir';
    static const _CONF_OUTPUT_DIR         = 'output_dir';
    static const _CONF_DATA_DIR           = 'data_dir';
    static const _CONF_PARTIALS_DIR       = 'partials_dir';
    static const _CONF_ASSETS_DIR         = 'assets_dir';
    static const _CONF_WORKSPACE_DIR      = 'workspace';
    static const _CONF_DATE_FORMAT        = 'date_format';
    static const _CONF_YAML_DELIMITER     = 'yaml_delimeter';
    static const _CONF_USE_MARKDOWN       = 'use_markdown';
    static const _CONF_DEFAULT_TEMPLATE   = 'default_template';
    static const _CONF_SITE_OPTIONS       = 'site_options';
    static const _CONF_SASS_COMPILER      = 'sasscompiler';
    static const _CONF_USE_SASS           = 'usesass';
    static const _CONF_USE_AUTOPREFIXER   = 'autoprefixer';
    static const _CONF_TALK_TO_ME         = 'talktome';
    static const _CONF_BROWSER            = 'browser';

    static const _CONF_ADDITIONAL_WATCH_FOLDER1 = "watchfolder1";
    static const _CONF_ADDITIONAL_WATCH_FOLDER2 = "watchfolder2";
    static const _CONF_ADDITIONAL_WATCH_FOLDER3 = "watchfolder3";

    final ArgResults _argResults;
    final Map<String,dynamic> _settings = new Map<String,dynamic>();

    Config(this._argResults) {

        _settings[Options._ARG_LOGLEVEL]            = 'info';

        _settings[Config._CONF_CONTENT_DIR]         = '${_CONFIG_FOLDER}/html/_content';
        _settings[Config._CONF_TEMPLATE_DIR]        = '${_CONFIG_FOLDER}/html/_templates';
        _settings[Config._CONF_DATA_DIR]            = '${_CONFIG_FOLDER}/html/_data';
        _settings[Config._CONF_PARTIALS_DIR]        = '${_CONFIG_FOLDER}/html/_partials';
        _settings[Config._CONF_ASSETS_DIR]          = '${_CONFIG_FOLDER}/html/_assets';

        _settings[Config._CONF_OUTPUT_DIR]          = 'web';
        _settings[Config._CONF_WORKSPACE_DIR]       = '.';
        _settings[Config._CONF_DATE_FORMAT]         = 'dd.MM.yyyy';
        _settings[Config._CONF_YAML_DELIMITER]      = '~~~';
        _settings[Config._CONF_USE_MARKDOWN]        = true;
        _settings[Config._CONF_DEFAULT_TEMPLATE]    = "default.html";
        _settings[Config._CONF_SASS_COMPILER]       = "sassc";
        _settings[Config._CONF_BROWSER]             = "Chromium";

        _settings[Config._CONF_SITE_OPTIONS]        = {};

        _settings[Options._ARG_IP]                  = "127.0.0.1";
        _settings[Options._ARG_PORT]                = "8080";

        _settings[Options._ARG_DOCROOT]             = _settings[Config._CONF_OUTPUT_DIR]; // web

        _settings[Config._CONF_USE_SASS]            = true;
        _settings[Config._CONF_USE_AUTOPREFIXER]    = true;
        _settings[Config._CONF_TALK_TO_ME]          = _runsOnOSX();

        _settings[Config._CONF_ADDITIONAL_WATCH_FOLDER1]  = "";
        _settings[Config._CONF_ADDITIONAL_WATCH_FOLDER2]  = "";
        _settings[Config._CONF_ADDITIONAL_WATCH_FOLDER3]  = "";

        _overwriteSettingsWithConfigFile();
        _overwriteSettingsWithArgResults();
    }

    List<String> get dirstoscan => _argResults.rest;

    String get configfolder => _CONFIG_FOLDER;

    String get configfile => "site.yaml";

    String get loglevel => _settings[Options._ARG_LOGLEVEL];

    String get contentfolder => _settings[Config._CONF_CONTENT_DIR];

    String get templatefolder => _settings[Config._CONF_TEMPLATE_DIR];

    String get outputfolder => _settings[Config._CONF_OUTPUT_DIR];

    String get datafolder => _settings[Config._CONF_DATA_DIR];

    String get partialsfolder => _settings[Config._CONF_PARTIALS_DIR];

    String get assetsfolder => _settings[Config._CONF_ASSETS_DIR];

    String get workspace => _settings[Config._CONF_WORKSPACE_DIR];

    String get dateformat => _settings[Config._CONF_DATE_FORMAT];

    String get yamldelimeter => _settings[Config._CONF_YAML_DELIMITER];

    bool get usemarkdown => _settings[Config._CONF_USE_MARKDOWN];

    String get defaulttemplate => _settings[Config._CONF_DEFAULT_TEMPLATE];

    String get sasscompiler => _settings[Config._CONF_SASS_COMPILER];

    Map<String,String> get siteoptions => _settings[Config._CONF_SITE_OPTIONS];

    String get ip => _settings[Options._ARG_IP];

    String get port => _settings[Options._ARG_PORT];

    String get docroot => _settings[Options._ARG_DOCROOT];

    bool get usesass => _settings[Config._CONF_USE_SASS];

    bool get useautoprefixer => _settings[Config._CONF_USE_AUTOPREFIXER];

    bool get talktome => _settings[Config._CONF_TALK_TO_ME];

    String get browser =>  _settings[Config._CONF_BROWSER];

    String get watchfolder1 => _settings[Config._CONF_ADDITIONAL_WATCH_FOLDER1];
    String get watchfolder2 => _settings[Config._CONF_ADDITIONAL_WATCH_FOLDER2];
    String get watchfolder3 => _settings[Config._CONF_ADDITIONAL_WATCH_FOLDER3];

    Map<String,String> get settings {
        final Map<String,String> settings = new Map<String,String>();

        settings["loglevel"]                                = loglevel;

        settings["Content folder"]                          = contentfolder;
        settings["Template folder"]                         = templatefolder;
        settings["Data folder"]                             = datafolder;
        settings["Partials folder"]                         = partialsfolder;
        settings["Assets folder"]                           = assetsfolder;

        settings["Default template"]                        = defaulttemplate;
        settings["Output folder"]                           = outputfolder;
        settings["Workspace"]                               = workspace;

        settings["Dateformat"]                              = dateformat;
        settings["YAML-Delimeter"]                          = yamldelimeter;

        settings["Use markdown"]                            = usemarkdown ? "yes" : "no";
        settings["Use SASS"]                                = usesass ? "yes" : "no";
        settings["Use Autoprefixer"]                        = useautoprefixer ? "yes" : "no";
        settings["Talk to me"]                              = talktome ? "yes" : "no";

        settings["Site options"]                            = siteoptions.toString();

        settings["Config folder"]                           = configfolder;
        settings["Config file"]                             = configfile;

        settings["SASS compiler"]                           = sasscompiler;
        settings["Browser"]                                 = browser;

        settings["IP-Address"]                              = ip;
        settings["Port"]                                    = port;
        settings["Document root"]                           = docroot;

        settings["Additional watchfolder1"]                 = watchfolder1.isNotEmpty ? watchfolder1 : "<not set>";
        settings["Additional watchfolder2"]                 = watchfolder1.isNotEmpty ? watchfolder2 : "<not set>";
        settings["Additional watchfolder3"]                 = watchfolder1.isNotEmpty ? watchfolder3 : "<not set>";

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

        if(_argResults.wasParsed(Options._ARG_IP)) {
            _settings[Options._ARG_IP] = _argResults[Options._ARG_IP];
        }

        if(_argResults.wasParsed(Options._ARG_PORT)) {
            _settings[Options._ARG_PORT] = _argResults[Options._ARG_PORT];
        }

        if(_argResults.wasParsed(Options._ARG_DOCROOT)) {
            _settings[Options._ARG_DOCROOT] = _argResults[Options._ARG_DOCROOT];
        }

        if(_argResults.wasParsed(Options._ARG_USE_SASS)) {
            _settings[Config._CONF_USE_SASS] = _argResults[Options._ARG_USE_SASS];
        }

        if(_argResults.wasParsed(Options._ARG_USE_AUTOPREFIXER)) {
            _settings[Config._CONF_USE_AUTOPREFIXER] = _argResults[Options._ARG_USE_AUTOPREFIXER];
        }

        if(_argResults.wasParsed(Options._ARG_USE_AUTOPREFIXER)) {
            _settings[Config._CONF_USE_AUTOPREFIXER] = _argResults[Options._ARG_USE_AUTOPREFIXER];
        }

        if(_argResults.wasParsed(Options._ARG_TALK_TO_ME)) {
            _settings[Config._CONF_TALK_TO_ME] = _argResults[Options._ARG_TALK_TO_ME];
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