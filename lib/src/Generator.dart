part of sitegen;

/**
 * Takes a template string (such as a Mustache template) and renders it out to an HTML string
 * using the given input values/options.
 */
typedef String TemplateRenderer(final String template,final Map options, final PartialsResolver resolver);

/// Resolved partial-names into mustache.Templates
typedef mustache.Template PartialsResolver(final String name);

/**
 * Can be set to define a custom [rendering function](TemplateRenderer) to handle your template files
 * and use any templating language of your choice.
 *
 * Uses [Mustache templates](https://pub.dartlang.org/packages/mustache) by default.
 */
TemplateRenderer renderTemplate = (final String source,final Map options, final PartialsResolver resolver) {
    final mustache.Template template =
        new mustache.Template(source,htmlEscapeValues: false, partialResolver: resolver,lenient: true);

    return template.renderString(options);
};

class Generator {
    final Logger _logger = new Logger("sitegen.Generator");

    /// Mustache-Renderer strips out newlines
    static const String _NEWLINE_PROTECTOR = "@@@#@@@";

    /// Render and output your static site (WARNING: overwrites existing HTML files in output directory).
    void generate(final Config config) {
        final Directory contentDir = new Directory(path.absolute(config.contentfolder));
        final Directory templateDir = new Directory(path.absolute(config.templatefolder));
        final Directory outputDir = new Directory(path.absolute( config.outputfolder));
        final Directory dataDir = new Directory(path.absolute( config.datafolder));
        final Directory partialsDir = new Directory(path.absolute( config.partialsfolder));
        final Directory assetsDir = new Directory(path.absolute( config.assetsfolder));

        Validate.isTrue(contentDir.existsSync(),"ContentDir ${contentDir.path} must exist!");
        Validate.isTrue(templateDir.existsSync(),"Templatefolder ${templateDir.path} must exist!");
        Validate.isTrue(outputDir.existsSync(),"OutputDir ${outputDir.path} must exist!");

        final List<File> files = _listContentFilesIn(contentDir);
        final List<File> images = _listImagesFilesIn(contentDir);
        final List<File> assets = _listAssetsFilesIn(assetsDir);
        final List<File> templates = _listTemplatesIn(templateDir);
        final List<File> dataFiles = dataDir.existsSync() ? _listDataFilesIn(dataDir) : new List<File>();

        final Map dataMap = _getDataMap(dataFiles);

        _logger.info("Generating .html files...");
        for (final File file in files) {
            final String relativeFileName = file.path.replaceAll("${contentDir.path}","").replaceFirst("/","");
            final String relativePath = path.dirname(relativeFileName).replaceFirst(".","");
            final String extension = path.extension(relativeFileName).replaceFirst(".","").toLowerCase();

            _logger.fine("\nFile: ${relativeFileName}, Path: $relativePath");
            final List<String> lines = file.readAsLinesSync();
            Map<String,dynamic> pageOptions = <String,dynamic>{};

            final bool hasYamlBlock = _hasYamlBlock(config.yamldelimeter,lines,extension);
            if (hasYamlBlock) {
                List<String> yamlBlock = _extractYamlBlockFrom(config.yamldelimeter,lines,extension);
                if(yamlBlock.length > 0) {
                    final String block = yamlBlock.join('\n');
                    final yaml.YamlMap ym = yaml.loadYaml(block);

                    pageOptions.addAll(ym.map((key,value)
                        => MapEntry<String,String>(key.toString(),value.toString())));

                    _resolvePartialsInYamlBlock(partialsDir,pageOptions,config.usemarkdown);

                    // +1 for the YAML-Block-Delimiter ("~~~") line
                    lines.removeRange(0, yamlBlock.length + 1);
                } else {
                    lines.removeRange(0,1);
                }
            }

            pageOptions = _fillInPageNestingLevel(relativeFileName,pageOptions);
            pageOptions = _fillInDefaultPageOptions(config.dateformat,file, pageOptions,config.siteoptions);
            pageOptions['_data'] = dataMap;
            pageOptions['_content'] = renderTemplate(lines.join('\n'), pageOptions,
                _partialsResolver(partialsDir,isMarkdownSupported: config.usemarkdown)
            );

            pageOptions['_template'] = "none";

            String outputExtension = extension;
            if (isMarkdown(file) && _isMarkdownSupported(config.usemarkdown, pageOptions)) {
                pageOptions['_content'] = md.markdownToHtml(pageOptions['_content']);
                outputExtension = "html";
            }

            String templateContent = "{{_content}}";
            if(hasYamlBlock == true && ( pageOptions.containsKey("template") == false || pageOptions["template"] != "none")) {
                final File template = _getTemplateFor(file, pageOptions, templates, config.defaulttemplate);
                pageOptions['_template'] = template.path;
                _logger.fine("Template: ${path.basename(template.path)}");

                templateContent = template.readAsStringSync();
            }

            if(config.loglevel == "debug") {
                _showPageOptions(relativeFileName,relativePath,pageOptions,config);
            }

            final String content = _fixPathRefs(renderTemplate(templateContent, pageOptions,
                _partialsResolver(partialsDir,isMarkdownSupported: config.usemarkdown)
                ),config);

            final String outputFilename = "${path.basenameWithoutExtension(relativeFileName)}.${outputExtension}";
            final Directory outputPath = _createOutputPath(outputDir,relativePath);
            final File outputFile = new File("${outputPath.path}/$outputFilename");

            outputFile.writeAsStringSync(content);
            _logger.info("   ${outputFile.path.replaceFirst(outputDir.path,"")} - done!");
        }

        for(final File image in images) {
            final String relativeFileName = image.path.replaceAll("${contentDir.path}","").replaceFirst("/","");
            final String relativePath = path.dirname(relativeFileName).replaceFirst(".","");

            final Directory outputPath = _createOutputPath(outputDir,relativePath);
            final File outputFile = new File("${outputPath.path}/${path.basename(relativeFileName)}");
            image.copySync(outputFile.path);

            _logger.info("   ${outputFile.path.replaceFirst(outputDir.path,"")} - copied!");
        }

        for(final File asset in assets) {
            final String relativeFileName = asset.path.replaceAll("${assetsDir.path}","").replaceFirst("/","");
            final String relativePath = path.dirname(relativeFileName).replaceFirst(".","");

            final Directory outputPath = _createOutputPath(outputDir,relativePath);
            final File outputFile = new File("${outputPath.path}/${path.basename(relativeFileName)}");
            asset.copySync(outputFile.path);

            _logger.info("   ${outputFile.path.replaceFirst(outputDir.path,"")} - copied!");
        }

    }


    // -- private -------------------------------------------------------------

    /**
     * If there is a reference to a partial in the yaml block the contents of the partial becomes the the
     * contents of the page-var.
     *
     * Example: yaml-block in file
     *  ...
     *  dart: ->usage.badge.dart
     *  ~~~
     *
     *  dart is the page-var.
     *  usage.badge.dart is the partial.
     */
    void _resolvePartialsInYamlBlock(final Directory partialsDir,final Map<String, dynamic> pageOptions,bool useMarkdown) {
        pageOptions.keys.forEach((final String key) {
            if(pageOptions[key] is String && (pageOptions[key] as String).contains("->")) {
                final String partial = (pageOptions[key] as String).replaceAll(new RegExp(r"[^>]*>"),"");
                pageOptions[key] = renderTemplate("{{>${partial}}}", pageOptions,
                _partialsResolver(partialsDir,isMarkdownSupported: useMarkdown));
            }
        });
    }

    /**
     * Returns a partials-Resolver. The partials-Resolver gets a dot separated name. This name is translated
     * into a filename / directory in _partials.
     * Example:
     *  Name: category.house -> category/house.[html | md]
     */
    PartialsResolver _partialsResolver(final Directory partialsDir,{ final bool isMarkdownSupported: true}) {
        Validate.notNull(partialsDir);

        mustache.Template resolver(final String name) {
            final File partialHtml = new File("${partialsDir.path}/${name.replaceAll(".","/")}.html");
            final File partialMd = new File("${partialsDir.path}/${name.replaceAll(".","/")}.md");

            String content = "Partial with name {{$name}} is not available";
            if(partialHtml.existsSync()) {
                content = partialHtml.readAsStringSync();
            } else if(partialMd.existsSync()) {
                content = partialMd.readAsStringSync();
                if(isMarkdownSupported) {
                    content = md.markdownToHtml(content);
                }
            }

            return new mustache.Template(content,name: "{{$name}}");
        }

        return resolver;
    }

    Directory _createOutputPath(final Directory outputDir, final String relativePath) {
        Validate.notNull(outputDir);

        final Directory outputPath = new Directory("${outputDir.path}${relativePath.isNotEmpty ? "/" : ""}${relativePath}");
        if(!outputPath.existsSync()) {
            outputPath.createSync(recursive: true);
        }
        return outputPath;
    }

    bool isMarkdown(final File file) {
        final String extension = path.extension(file.path).toLowerCase();
        return extension == ".md" || extension == ".markdown";
    }

    List<File> _listContentFilesIn(final Directory contentDir) {
        if(!contentDir.existsSync()) {
            return new List<File>();
        }

        return contentDir.listSync(recursive: true)
            .where((final FileSystemEntity entity) => entity is File && (

                entity.path.endsWith('.md') ||
                entity.path.endsWith(".markdown") ||
                entity.path.endsWith(".dart") ||
                entity.path.endsWith(".js") ||
                entity.path.endsWith(".json") ||
                entity.path.endsWith(".html") ||
                entity.path.endsWith(".scss") ||
                entity.path.endsWith(".css") ||
                entity.path.endsWith(".svg"))
            && !entity.path.contains("packages") )
            .map((final FileSystemEntity entity) => entity as File)
            .toList();
    }

    List<File> _listImagesFilesIn(final Directory contentDir) {
        return contentDir.listSync(recursive: true)
        .where((file) => file is File && (

            file.path.endsWith('.png') ||
            file.path.endsWith(".jpg") ||
            file.path.endsWith(".gif")

        ) && !file.path.contains("packages") )
            .map((final FileSystemEntity entity) => entity as File)
            .toList();
    }

    List<File> _listAssetsFilesIn(final Directory contentDir) {
        if(!contentDir.existsSync()) {
            return new List<File>();
        }

        return contentDir.listSync(recursive: true)
        .where((file) => file is File && (

            file.path.endsWith(".png") ||
            file.path.endsWith(".jpg") ||
            file.path.endsWith(".scss") ||
            file.path.endsWith(".css") ||
            file.path.endsWith(".svg")

        ) && !file.path.contains("packages") )
            .map((final FileSystemEntity entity) => entity as File)
            .toList();
    }


    List<File> _listTemplatesIn(final Directory templateDir) {
        return templateDir.listSync().where((file) => file is File && !file.path.contains("packages"))
            .map((final FileSystemEntity entity) => entity as File)
            .toList();
    }

    List<File> _listDataFilesIn(final Directory contentDir) {
        return contentDir.listSync(recursive: true)
        .where((file) => file is File && (

            file.path.endsWith('.yaml') ||
            file.path.endsWith(".json")

        ) && !file.path.contains("packages"))
            .map((final FileSystemEntity entity) => entity as File)
            .toList();
    }

    bool _isMarkdownSupported(final bool markdownForSite, final Map page_options) {
        return markdownForSite || ( page_options.containsKey('markdown_templating') && page_options['markdown_templating'] );
    }

    bool _hasYamlBlock(final String delimiter, final List<String> content,final String forExtension) {
        Validate.notBlank(delimiter);
        Validate.notEmpty(content);

        final String startsWithString = _startStringForYamlBlock(delimiter,forExtension);
        final String endsWithString = delimiter.substring(delimiter.length - 2, delimiter.length - 1);

        bool hasYamlBlock = content.any( (line) => line.startsWith(startsWithString) && line.endsWith(endsWithString));
        return hasYamlBlock;
    }

    List<String> _extractYamlBlockFrom(final String delimiter, final List<String> content,final String forExtension) {
        Validate.notBlank(delimiter);
        Validate.notEmpty(content);
        Validate.notBlank(forExtension);

        final String yamlStartBlock = _startStringForYamlBlock(delimiter,forExtension);
        final List<String> lines = content.takeWhile( (line) => !line.startsWith(yamlStartBlock)).toList();
        final List<String> yamlBlock = new List<String>();

        switch(forExtension) {
            case "dart":
                lines.forEach((final String line) {
                    yamlBlock.add(line.replaceFirst(new RegExp(r"// "),""));
                });
                break;

            default:
                yamlBlock.addAll(lines);
                break;
        }
        return yamlBlock;
    }

    String _startStringForYamlBlock(final String delimiter,final String forExtension) {
        Validate.notBlank(delimiter);
        Validate.notBlank(forExtension);

        String startsWithString = delimiter;
        switch(forExtension) {
            case "dart":
                startsWithString = "//$delimiter";
                break;
        }
        return startsWithString;
    }

    Map<String,dynamic> _fillInDefaultPageOptions(final String defaultDateFormat,final File file,final Map<String,dynamic> pageOptions,final Map<String,String> siteOptions) {
        final String filename = path.basenameWithoutExtension(file.path);
        pageOptions.putIfAbsent('title', () => filename);

        pageOptions['_site'] = siteOptions;

        //_logger.info(pageOptions.toString());

        /// See [DateFormat](https://api.dartlang.org/docs/channels/stable/latest/intl/DateFormat.html) for formatting options
        var date_format = new DateFormat(defaultDateFormat);

        if (pageOptions.containsKey('date_format')) {
            var page_date_format = new DateFormat(pageOptions['date_format']);
            pageOptions['_date'] = page_date_format.format(file.lastModifiedSync());
        }
        else {
            pageOptions['_date'] = date_format.format(file.lastModifiedSync());
        }

        return pageOptions;
    }

    Map _getDataMap(final List<File> dataFiles) {
        final Map<String,dynamic> dataMap = new Map<String,dynamic>();

        dataFiles.forEach((final File file) {
            if(file.existsSync()) {
                var data;
                if(path.extension(file.path) == ".yaml") {

                    data = yaml.loadYaml(file.readAsStringSync());

                } else {

                    data = json.decode(file.readAsStringSync());
                }

                final String filename = path.basenameWithoutExtension(file.path).toLowerCase();
                dataMap[filename] = data;
            }
        });

        return dataMap;
    }

    /**
     * Sample: <link rel="stylesheet" href="{{_page.relative_to_root}}/styles/main.css">
     *   produces <link rel="stylesheet" href="../styles/main.css"> for about/index.html
     *
     * Sample:
     *   <a href="index.html" class="mdl-layout__tab {{#_page.index}}{{_page.index}}{{/_page.index}}">Overview</a>
     *   produces:
     *      <a href="index.html" class="mdl-layout__tab is-active">Overview</a>
     *   if the current page is index.html
     */
    Map<String,dynamic> _fillInPageNestingLevel(final String relativeFileName, Map<String,dynamic> pageOptions) {
        Validate.notBlank(relativeFileName);

        String backPath = "";
        int nestingLevel = 0;
        if(relativeFileName.contains("/")) {
            nestingLevel = relativeFileName.split("/").length - 1;
            for(int counter = 0; counter < nestingLevel; counter++) {
                backPath = backPath + "../";
            }
        }

        final String pathWithoutExtension = path.withoutExtension(relativeFileName);
        // final String portablePath = pathWithoutExtension.replaceAll(new RegExp("(/|\\\\\)"),":");
        final String pageIndicator = pathWithoutExtension.replaceAll(new RegExp("(/|\\\\\)"),"_");
        pageOptions["_page"] = {
            "filename" : pathWithoutExtension,
            "pageindicator" : pageIndicator,
            "relative_to_root" : backPath,
            "nesting_level" : nestingLevel,

            /// you can use this like
            ///     {{#_page.index}}{{_page.index}}{{/_page.index}
            pageIndicator : "is-active",
        };

        return pageOptions;
    }

    File _getTemplateFor(final File file,final Map page_options,final List<File> templates, final String defaultTemplate) {
        final String filenameWithoutExtension = path.basenameWithoutExtension(file.path);
        final String filepath = path.normalize(file.path);

        File template;
        //_logger.info("Templates: ${templates}, Default: ${defaultTemplate}");

        try {
            if (page_options.containsKey('template')) {
                template = templates.firstWhere( (final File file) => path.basenameWithoutExtension(file.path) == page_options['template']);
            }
            else if (defaultTemplate.isNotEmpty) {
                template = templates.firstWhere( (final File file) {
                    return path.basenameWithoutExtension(file.path) == path.basenameWithoutExtension(defaultTemplate);
                });
            }
            else {
                template = templates.firstWhere( (final File file ) => path.basenameWithoutExtension(file.path) == filenameWithoutExtension);
            }
        }
        catch (e) {
            throw "No template given for '$filepath!";
        }

        return template;
    }


    /**
     * Redirect resource links using relative paths to the output directory.
     * Currently only supports replacing Unix-style relative paths.
     */
    String _fixPathRefs(String html,final Config config) {
        var relative_output = path.relative(config.outputfolder, from: config.templatefolder);

        relative_output = "$relative_output/".replaceAll("\\", "/");
        //_logger.info(relative_output);

        html = html.replaceAll('src="$relative_output', 'src="')
        .replaceAll('href="$relative_output', 'href="');

        return html;
    }

//    /**
//     * Removes everything before ~~~
//     */
//    String _removeYamlBlock(String fileContent,final Config config) {
//
//        fileContent = fileContent.replaceFirst(new RegExp("(?:.|\n)*${config.yamldelimeter}(?:\r\n|\n)",multiLine: true),"");
//
//        /// if there is something like ~~~ (xtreme-sample)
//        fileContent = fileContent.replaceFirst(new RegExp("^${config.yamldelimeter}\$"),"");
//
//        /// Replace all newlines with some silly characters to protect the newlines because
//        /// Mustache-Renderer strips them
//        fileContent = fileContent.replaceAll(new RegExp("\n",multiLine: true),_NEWLINE_PROTECTOR);
//
//        return fileContent;
//    }

    /**
     * Shows all the available vars for the current page
     */
    void _showPageOptions(final String relativeFileName,final String relativePath,
        final Map<String, dynamic> pageOptions,final Config config) {

        Validate.notBlank(relativeFileName);
        Validate.notNull(relativePath);
        Validate.notNull(pageOptions);
        Validate.notNull(config);

        _logger.fine("   --- ${(relativeFileName + " ").padRight(76,"-")}");

        void _showMap(final Map<String, dynamic> values,final int nestingLevel) {
            values.forEach((final String key,final dynamic value) {
                _logger.fine("    ${"".padRight(nestingLevel * 2)} $key.");

                if(value is Map) {
                    _showMap(value as Map<String,dynamic>,nestingLevel + 1);

                } else {
                    String valueAsString = value.toString().replaceAll(new RegExp("(\n|\r|\\s{2,}|${_NEWLINE_PROTECTOR})",multiLine: true),"");

                    valueAsString = valueAsString.substring(0,min(50,max(valueAsString.length,0)));
                    _logger.fine("    ${"".padRight(nestingLevel * 2)} $key -> [${valueAsString}]");
                }
            });
        }

        _showMap(pageOptions,0);
        _logger.fine("   ${"".padRight(80,"-")}");
    }
}
