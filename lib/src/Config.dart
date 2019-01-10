part of sitegen;

/**
 * Defines default-configurations.
 * Most of these configs can be overwritten by commandline args.
 */
class Config {
    final Logger _logger = new Logger("sitegen.Config");

    static const String _CONFIG_FOLDER     = ".sitegen";

    static const _CONF_CONTENT_DIR              = 'content_dir';
    static const _CONF_TEMPLATE_DIR             = 'template_dir';
    static const _CONF_OUTPUT_DIR               = 'output_dir';
    static const _CONF_DATA_DIR                 = 'data_dir';
    static const _CONF_PARTIALS_DIR             = 'partials_dir';
    static const _CONF_ASSETS_DIR               = 'assets_dir';
    static const _CONF_WORKSPACE_DIR            = 'workspace';
    static const _CONF_DATE_FORMAT              = 'date_format';
    static const _CONF_YAML_DELIMITER           = 'yaml_delimeter';
    static const _CONF_USE_MARKDOWN             = 'use_markdown';
    static const _CONF_DEFAULT_TEMPLATE         = 'default_template';
    static const _CONF_SITE_OPTIONS             = 'site_options';
    static const _CONF_SASS_COMPILER            = 'sasscompiler';
    static const _CONF_SASS_PATH                = 'sass_path';
    static const _CONF_USE_SASS                 = 'usesass';
    static const _CONF_USE_AUTOPREFIXER         = 'autoprefixer';
    static const _CONF_TALK_TO_ME               = 'talktome';
    static const _CONF_BROWSER                  = 'browser';
    static const _CONF_PORT                     = 'port';

    static const _CONF_USE_SECURE_CONNECTION    = 'usesec';
    static const _CONF_CERT_FILE                = 'cert_file';
    static const _CONF_KEY_FILE                 = 'key_file';

    static const _CONF_ADDITIONAL_WATCH_FOLDER1 = "watchfolder1";
    static const _CONF_ADDITIONAL_WATCH_FOLDER2 = "watchfolder2";
    static const _CONF_ADDITIONAL_WATCH_FOLDER3 = "watchfolder3";

    static final String _SEARCH_PATH_SEPARATOR = Platform.isWindows ? ";" : ":";

    final ArgResults _argResults;
    final Map<String,dynamic> _settings = new Map<String,dynamic>();
    final Packages _packages = new Packages();
    final CommandManager _commandmanager;

    Config(this._argResults, this._commandmanager) {

        _settings[Options._ARG_LOGLEVEL]                = 'info';

        _settings[Config._CONF_CONTENT_DIR]             = '${_CONFIG_FOLDER}/html/_content';
        _settings[Config._CONF_TEMPLATE_DIR]            = '${_CONFIG_FOLDER}/html/_templates';
        _settings[Config._CONF_DATA_DIR]                = '${_CONFIG_FOLDER}/html/_data';
        _settings[Config._CONF_PARTIALS_DIR]            = '${_CONFIG_FOLDER}/html/_partials';
        _settings[Config._CONF_ASSETS_DIR]              = '${_CONFIG_FOLDER}/html/_assets';

        _settings[Config._CONF_OUTPUT_DIR]              = 'web';
        _settings[Config._CONF_WORKSPACE_DIR]           = '.';
        _settings[Config._CONF_DATE_FORMAT]             = 'dd.MM.yyyy';
        _settings[Config._CONF_YAML_DELIMITER]          = '~~~';
        _settings[Config._CONF_USE_MARKDOWN]            = true;
        _settings[Config._CONF_DEFAULT_TEMPLATE]        = "default.html";
        _settings[Config._CONF_SASS_COMPILER]           = _commandmanager.containsKey("sassc") ? "sassc" : "sass";
        _settings[Config._CONF_SASS_PATH]               = "";
        _settings[Config._CONF_BROWSER]                 = "Chromium";

        _settings[Config._CONF_BROWSER]                 = "Chromium";

        _settings[Config._CONF_SITE_OPTIONS]            = <String,String>{};

        _settings[Options._ARG_IP]                      = "127.0.0.1";
        _settings[Config._CONF_PORT]                    = "8080";

        _settings[Options._ARG_DOCROOT]                 = _settings[Config._CONF_OUTPUT_DIR]; // web

        _settings[Config._CONF_USE_SASS]                = false;
        _settings[Config._CONF_USE_AUTOPREFIXER]        = true;

        _settings[Config._CONF_USE_SECURE_CONNECTION]   = false;
        _settings[Config._CONF_CERT_FILE]               = 'dart.crt';
        _settings[Config._CONF_KEY_FILE]                = 'dart.key';

        _settings[Config._CONF_TALK_TO_ME]              = _runsOnOSX();

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

    String get sasspath => _sasspath;

    Map<String,String> get siteoptions => _toMap(_settings[Config._CONF_SITE_OPTIONS]);

    String get ip => _settings[Options._ARG_IP];

    String get port => _settings[Config._CONF_PORT].toString();

    String get docroot => _settings[Options._ARG_DOCROOT];

    bool get usesass => _settings[Config._CONF_USE_SASS];

    bool get useautoprefixer => _settings[Config._CONF_USE_AUTOPREFIXER];

    bool get usesecureconnection => _settings[Config._CONF_USE_SECURE_CONNECTION];

    String get certfile => _settings[Config._CONF_CERT_FILE];
    String get keyfile => _settings[Config._CONF_KEY_FILE];

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

        settings["Use secure connection"]                   = usesecureconnection ? "yes" : "no";
        settings["Cert-file for secure connection"]         = certfile;
        settings["Key-file for secure connection"]          = keyfile;

        settings["Talk to me"]                              = talktome ? "yes" : "no";

        settings["Site options"]                            = siteoptions.toString();

        settings["Config folder"]                           = configfolder;
        settings["Config file"]                             = configfile;

        settings["SASS compiler"]                           = sasscompiler;
        settings["SASS_PATH (only for sass)"]               = sasspath.isNotEmpty ? _sasspath : "<not set>";
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

        final int maxKeyLength = getMaxKeyLength();

        String prepareKey(final String key) {
            if(!key.isEmpty) {
                return "${key[0].toUpperCase()}${key.substring(1)}:".padRight(maxKeyLength + 1);
            } else {
                // this is only the case if setting is "sass_path..."
                return key.padRight(maxKeyLength + 1);
            }
        }

        print("Settings:");
        //print("    ${'Name'.padRight(maxKeyLeght)}  ${'Value'.padRight(25)} ${'Key (site.yaml)'}");
        settings.forEach((final String key,final value) {
            if(key.toLowerCase().startsWith("sass_path") && sasspath.isNotEmpty) {
                final List<String> segments = value.split(_SEARCH_PATH_SEPARATOR);
                print("    ${prepareKey(key)} ${segments.first}");
                segments.skip(1).forEach((final String path) {
                    print("    ${prepareKey('')} $path");
                });

            } else {
                print("    ${prepareKey(key)} ${value}");
            }
        });

        _commandmanager._commands.forEach((final String name,final Command command) {
            print("    ${prepareKey(name)} ${command.exe}");
        });
    }

    void printSiteKeys() {
        print("Keys for ${configfile}:");
        _settings.forEach((final String key,final dynamic value) {
            print("    ${(key + ':').padRight(20)} $value");
        });
    }

    // -- private -------------------------------------------------------------

    void _overwriteSettingsWithArgResults() {
        if(_argResults.wasParsed(Options._ARG_LOGLEVEL)) {
            _settings[Options._ARG_LOGLEVEL] = _argResults[Options._ARG_LOGLEVEL];
        }

        if(_argResults.wasParsed(Options._ARG_IP)) {
            _settings[Options._ARG_IP] = _argResults[Options._ARG_IP];
        }

        if(_argResults.wasParsed(Options._ARG_PORT)) {
            _settings[Config._CONF_PORT] = _argResults[Options._ARG_PORT];
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

        if(_argResults.wasParsed(Options._ARG_USE_SECURE_CONNECTION)) {
            _settings[Config._CONF_USE_SECURE_CONNECTION] = _argResults[Options._ARG_USE_SECURE_CONNECTION];
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
                print("Found $key in $configfile: ${map[key]}");
            }
        });
    }
    /// Interprets the "sass_path" settings in .sitegen/site.yaml
    String get _sasspath {
        // Can be a String or a YamlList
        final pathInSettings = _settings[Config._CONF_SASS_PATH];

        // Nothing to do here - return an empty string
        if(pathInSettings.isEmpty) { return pathInSettings; }

        final List<String> tempPathList = new List<String>();
        if(pathInSettings is String) {

            // Config-Path can be separated by a |
            tempPathList.addAll(pathInSettings.split("|"));

        } else if(pathInSettings is yaml.YamlList) {

            pathInSettings.toList().forEach((final element) => tempPathList.add(element.toString()));

        } else {
            _logger.warning("sass_path must be either a String or a YamlList but was ${pathInSettings.runtimeType}...");
        }


        final List<String> sasspath = new List<String>();
        tempPathList.forEach((final String pathEntry) {
            if(pathEntry.startsWith("package:")) {
                final Uri uri = Uri.parse(pathEntry);
                try {
                    final Package package = _packages.resolvePackageUri(uri);
                    final String packageUri = package.uri.toString().replaceFirst("file://","");
                    sasspath.add(path.normalize(path.absolute(packageUri)));

                } catch( error) {
                    _logger.shout(error.toString());
                }

            } else {
                sasspath.add(path.normalize(pathEntry));
            }
        });

        if(sasspath.isEmpty) {
            return '';
        }

        return sasspath.join(_SEARCH_PATH_SEPARATOR);
    }

    Map<String,String> _toMap(final configOption) {
        if(configOption is Map<String,String>) {
            return configOption;
        }

        if(configOption is yaml.YamlMap) {
            return configOption
                .map((key,value) => MapEntry<String,String>(key.toString(),value.toString()));
            
        } else {
            return configOption;
        }

    }
}