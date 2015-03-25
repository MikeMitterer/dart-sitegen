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
        final Directory contentDir = new Directory(path.absolute(config.workspace, config.contentfolder));
        final Directory templateDir = new Directory(path.absolute(config.workspace, config.templatefolder));
        final Directory outputDir = new Directory(path.absolute(config.workspace, config.outputfolder));

        Validate.isTrue(contentDir.existsSync());
        Validate.isTrue(templateDir.existsSync());
        Validate.isTrue(outputDir.existsSync());

        // TODO: support directory hierarchies for markdown, templates and output
        final List<File> files = _listContentFilesIn(contentDir);
        final List<File> templates = _listTemplatesIn(templateDir);

        for (final File file in files) {
            // TODO: provide a way to access the list of pages with filenames and titles from a '_site' property
            _logger.info("File: ${path.basename(file.path)}");

            final List<String> lines = file.readAsLinesSync();
            Map<String,String> page_options = {};

            if (_hasYamlBlock(config.yamldelimeter,lines)) {
                var yaml_block = _extractYamlBlockFrom(config.yamldelimeter,lines);
                page_options.addAll(yaml.loadYaml(yaml_block.join('\n')));

                lines.removeRange(0, yaml_block.length + 1);
                // +1 for the YAML-Block-Delimiter ("~~~") line
            }

            page_options = _fillInDefaultPageOptions(config.dateformat,file, page_options,config.siteoptions);

            page_options['_content'] = renderTemplate(lines.join('\n'), page_options);

            if (isMarkdown(file) && _isMarkdownSupported(config.usemarkdown, page_options)) {
                page_options['_content'] = md.markdownToHtml(page_options['_content']);
            }

            final File template = _getTemplateFor(file, page_options, templates, config.defaulttemplate);
            _logger.info("   Template: ${path.basename(template.path)}");

            var template_str = template.readAsStringSync();
            final String content = _fixPathRefs(renderTemplate(template_str, page_options),config);

            final String filename = "${path.basenameWithoutExtension(file.path)}.html";
            final File outputFile = new File("${outputDir.path}/$filename");
            outputFile.writeAsStringSync(content);

            _logger.info("${filename} generated!\n");
        }

    }

    // -- private -------------------------------------------------------------
    bool isMarkdown(final File file) {
        final String extension = path.extension(file.path).toLowerCase();
        return extension == ".md" || extension == ".markdown";
    }

    List<File> _listContentFilesIn(final Directory contentDir) {
        return contentDir.listSync()
            .where((file) => file is File && (file.path.endsWith('.md') || file.path.endsWith(".markdown") || file.path.endsWith(".html"))).toList();
    }

    List<File> _listTemplatesIn(final Directory templateDir) {
        return templateDir.listSync().where((file) => file is File).toList();
    }

    bool _isMarkdownSupported(final bool markdownForSite, final Map page_options) {
        return markdownForSite || ( page_options.containsKey('markdown_templating') && page_options['markdown_templating'] );
    }

    bool _hasYamlBlock(final String delimiter, final List<String> content) {
        final String end_of_delimiter = delimiter.substring(delimiter.length - 2, delimiter.length - 1);
        return content.any((line) => line.startsWith(delimiter) && line.endsWith(end_of_delimiter));
    }

    List<String> _extractYamlBlockFrom(final String delimiter, final List<String> content) {
        return content.takeWhile((line) => !line.startsWith(delimiter)).toList();
    }

    Map _fillInDefaultPageOptions(final String defaultDateFormat,final File file, Map page_options,final Map<String,String> siteOptions) {
        final String filename = path.basenameWithoutExtension(file.path);
        page_options.putIfAbsent('title', () => filename);

        page_options['_site'] = siteOptions;

        /// See [DateFormat](https://api.dartlang.org/docs/channels/stable/latest/intl/DateFormat.html) for formatting options
        var date_format = new DateFormat(defaultDateFormat);

        if (page_options.containsKey('date_format')) {
            var page_date_format = new DateFormat(defaultDateFormat);
            page_options['_date'] = page_date_format.format(file.lastModifiedSync());
        }
        else {
            page_options['_date'] = date_format.format(file.lastModifiedSync());
        }

        return page_options;
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

        html = html.replaceAll('src="$relative_output', 'src="')
        .replaceAll('href="$relative_output', 'href="');

        return html;
    }
}
