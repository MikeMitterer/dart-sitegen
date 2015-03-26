part of dartpad;

/**
 * Takes a template string (such as a Mustache template) and renders it out to an HTML string
 * using the given input values/options.
 */
typedef String TemplateRenderer(final String template,final Map options);

/**
 * Can be set to define a custom [rendering function](TemplateRenderer) to handle your template files
 * and use any templating language of your choice.
 *
 * Uses [Mustache templates](https://pub.dartlang.org/packages/mustache) by default.
 */
TemplateRenderer renderTemplate = (final String templateFile,final Map options) {
    final mustache.Template template = new mustache.Template(templateFile,htmlEscapeValues: false);

    return template.renderString(options);
};

class Generator {
    final Logger _logger = new Logger("dartpad.Generator");

    /// Render and output your static site (WARNING: overwrites existing HTML files in output directory).
    void generate(final Config config) {
        final Directory contentDir = new Directory(path.absolute(config.contentfolder));
        final Directory templateDir = new Directory(path.absolute(config.templatefolder));
        final Directory outputDir = new Directory(path.absolute( config.outputfolder));

        Validate.isTrue(contentDir.existsSync(),"ContentDir ${contentDir.path} must exist!");
        Validate.isTrue(templateDir.existsSync(),"Templatefolder ${templateDir.path} must exist!");
        Validate.isTrue(outputDir.existsSync(),"OutputDir ${outputDir.path} must exist!");

        // TODO: support directory hierarchies for markdown, templates and output
        final List<File> files = _listContentFilesIn(contentDir);
        final List<File> templates = _listTemplatesIn(templateDir);

        _logger.info("Generating .html files...");
        for (final File file in files) {
            final String relativeFileName = file.path.replaceAll("${contentDir.path}","").replaceFirst("/","");
            final String relativePath = path.dirname(relativeFileName).replaceFirst(".","");
            final String extension = path.extension(relativeFileName).replaceFirst(".","").toLowerCase();

            _logger.fine("\nFile: ${relativeFileName}, Path: $relativePath");
            final List<String> lines = file.readAsLinesSync();
            Map<String,dynamic> pageOptions = {};

            final bool hasYamlBlock = _hasYamlBlock(config.yamldelimeter,lines,extension);
            if (hasYamlBlock) {
                List<String> yamlBlock = _extractYamlBlockFrom(config.yamldelimeter,lines,extension);
                if(yamlBlock.length > 0) {
                    pageOptions.addAll(yaml.loadYaml(yamlBlock.join('\n')));

                    // +1 for the YAML-Block-Delimiter ("~~~") line
                    lines.removeRange(0, yamlBlock.length + 1);
                } else {
                    lines.removeRange(0,1);
                }
            }

            pageOptions = _fillInPageNestingLevel(relativeFileName,pageOptions);
            pageOptions = _fillInDefaultPageOptions(config.dateformat,file, pageOptions,config.siteoptions);
            pageOptions['_content'] = renderTemplate(lines.join('\n'), pageOptions);

            String outputExtension = extension;
            if (isMarkdown(file) && _isMarkdownSupported(config.usemarkdown, pageOptions)) {
                pageOptions['_content'] = md.markdownToHtml(pageOptions['_content']);
                outputExtension = "html";
            }

            String templateContent = "{{_content}}";
            if(hasYamlBlock == true && ( pageOptions.containsKey("template") == false || pageOptions["template"] != "none")) {
                final File template = _getTemplateFor(file, pageOptions, templates, config.defaulttemplate);
                _logger.fine("Template: ${path.basename(template.path)}");
                templateContent = template.readAsStringSync();
            }

            final String content = _fixPathRefs(renderTemplate(templateContent, pageOptions),config);

            final String outputFilename = "${path.basenameWithoutExtension(relativeFileName)}.${outputExtension}";
            final Directory outputPath = _createOutputPath(outputDir,relativePath);
            final File outputFile = new File("${outputPath.path}/$outputFilename");

            outputFile.writeAsStringSync(content);
            _logger.info("   ${outputFile.path.replaceFirst(outputDir.path,"")} - done!");
        }
    }

    // -- private -------------------------------------------------------------

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
        return contentDir.listSync(recursive: true)
            .where((file) => file is File && (

                    file.path.endsWith('.md') ||
                    file.path.endsWith(".markdown") ||
                    file.path.endsWith(".dart") ||
                    file.path.endsWith(".js") ||
                    file.path.endsWith(".html") ||
                    file.path.endsWith(".scss") ||
                    file.path.endsWith(".css")

                    )).toList();
    }

    List<File> _listTemplatesIn(final Directory templateDir) {
        return templateDir.listSync().where((file) => file is File).toList();
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

    Map _fillInDefaultPageOptions(final String defaultDateFormat,final File file, Map pageOptions,final Map<String,String> siteOptions) {
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

    /**
     * Sample: <link rel="stylesheet" href="{{_page.relative_to_root}}styles/main.css">
     *   produces <link rel="stylesheet" href="../styles/main.css"> for about/index.html
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
        pageOptions["_page"] = {
            "relative_to_root" : backPath,
            "nesting_level" : nestingLevel
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
}
