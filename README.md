# SiteGen

A simple static site generator in [Dart][dart], webserver included.  
You can write your pages in HTML or [Markdown][markdown]. For Templates [Mustache][mustache] is supported.  

A webserver for a quick review is included. On Mac you also get automatic page refresh. On other 
platforms you could try [LivePage][livepage] chrome extension for maximum productivity.  

Before you read on - check out this video:

[![promoimage]][video]

[Here][example] you can see a typical site structure.  

```
├── .sitegen
│   ├── refreshChromium-1.0.applescript
│   └── site.yaml
├── html
│   ├── _content
│   │   ├── about
│   │   │   └── index.html
│   │   ├── index.html
│   │   ├── markdown.md
│   │   ├── piratenames.json
│   │   └── xtreme.html
│   └── _templates
│       ├── default.html
│       └── info_page.html
└── web
    ├── about
    │   ├── index.html
    │   └── packages -> ../../packages
    ├── index.html
    ├── main.dart
    ├── markdown.html
    ├── packages -> ../packages
    ├── piratenames.json
    ├── styles
    │   ├── main.css
    │   ├── main.scss
    │   └── packages -> ../../packages
    └── xtreme.html
```

**.sitegen**: This is where your site.yaml lives  
This folder is also used to store autgenerated scripts - in the case above you can see
the script to refresh Chromium on Mac.

**html/_content**: This is where **SiteGen** will look for your files to generate the site from.
The following file-formats are supported:

- .md
- .markdown
- .dart
- .js
- .json
- .html
- .scss
- .css
                    
**html/_templates**: The directory containing your HTML+Mustache templates.

**web**: Following Dart conventions - this is your default output directory.

## site.yaml
**Optional** [YAML][yaml] file that stores your global values and config options.
Values set here can be accessed from all templates and markdown files.

```
site_options:
  author: Mike Mitterer
```

Can be used in your template (default.html) as
```
<span>{{_site.author}}</span>
```

You can also use site.yaml to overwrite your **SiteGen** default configuration.  
Supported vars:

- content_dir: html/_content 
- template_dir: html/_templates
- output_dir: web
- workspace: .
- date_format: dd.MM.yyyy
- yaml_delimeter: ~~~
- use_markdown: true
- default_template: default.html
- sasscompiler: sassc

## Markdown
**SiteGen** lets you use [markdown][markdown] to write your site content. At the beginning of each markdown file, you
have the option to use a [YAML][yaml] block to define custom values that you can inject into your templates. Example:

    title: A Blog Post
    published: 01/01/2014
    category: example
    tags:
        - StillShot
        - Rants
        - Etc.
    ~~~~~~
    {{title}}
    Normal Markdown content here...

As you can see, a line of tildes (`~`) is used to designate your YAML block. You can access/inject your values into
your pages using [mustache template syntax][mustache]. You can do this either inside your dedicated HTML/mustache templates:

    <ul>
      {{#tags}}
        <li>{{.}}</li>
      {{/tags}}
    </ul>

Or, you can embed your values within the markdown file itself:

    {{#tags}}
      - __{{.}}__
    {{/tags}}

so you can take advantage of templating and markdown at the same time.

Simply place all your files in your `content_dir` and **SiteGen** will generate your site accordingly.      
If your markdown file has a .md extension it will be renamed to .html.
    
## Templates
As mentioned above, you can access any variables set within your markdown files from your templates using mustache. Options
set from your `site.yaml / site_options` can be accessed through the `_site` variable, like so:

    <h1>{{ _site.author}}</h1>

where `author` is a property defined in your `site.yaml / site_options`. 
You can access these values from your markdown or from your html files.

Every page and template has access to the following values:

- `title`: title, usually set inside each markdown file, but is set to the name of markdown file if left blank
- `_site`: site.yaml values
- `_date`: the post/markdown file's _last modified_ date
- `_content`: converted markdown content (only accessible from templates)
- `_page.relative_to_root`: will be replaced with some '../' depending on the nesting level of your page (check about/index.html)
    
The default template is 'default.html' but you can overwrite this behavior if you add a 'template' var to the yaml-block of your content file.

    template: info_page
    
## SASS
If SiteGen finds a .scss file in your output dir (web) it compiles it to the corresponding .css file.    
    
# Install
Install
```shell
    pub global activate sitegen
```

Update
```shell
    # activate sitegen again
    pub global activate sitegen
```

Uninstall
```shell
    pub global deactivate sitegen    
```    
    
## Usage    
```shell
    Usage: sitegen [options]
        -s, --settings    Prints settings
        -h, --help        Shows this message
        -g, --generate    Generate site
        -w, --watch       Observes SRC-dir
            --serve       Serves your site
            --port        Sets the port to listen on
                          (defaults to "8000")
    
        -v, --loglevel    Sets the appropriate loglevel
                          [info, debug, warning]
    
    Sample:
    
        'Observes the default dirs and serves the web-folder:  'sitegen -w --serve'
        'Generates the static site in your 'web-folder':       'sitegen -g'    
```

Go to your project root (this is where your pubspec.yaml is) and type:

    sitegen -w --serve
        
If you are using Chromium on Mac you will get a automatic page refresh for free!
 
Now play with sitegen and watch my screencast...

### Features and bugs
Please file feature requests and bugs at the [issue tracker][tracker].

### Thanks
I want to thank "Enrique Gavidia" for his [stillshot][stillshot] package that I used as basis for **SiteGen**. 

### License

    Copyright 2015 Michael Mitterer (office@mikemitterer.at),
    IT-Consulting and Development Limited, Austrian Branch

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
    either express or implied. See the License for the specific language
    governing permissions and limitations under the License.


If this plugin is helpful for you - please [(Circle)](http://gplus.mikemitterer.at/) me
or **star** this repo here on GitHub.

[dart]: https://www.dartlang.org/
[tracker]: https://github.com/MikeMitterer/dart-sitegen/issues
[markdown]: http://daringfireball.net/projects/markdown/syntax
[mustache]: http://mustache.github.io/mustache.5.html
[livepage]: https://chrome.google.com/webstore/detail/livepage/pilnojpmdoofaelbinaeodfpjheijkbh
[example]: https://github.com/MikeMitterer/dart-sitegen/tree/master/example/simple
[yaml]: http://rhnh.net/2011/01/31/yaml-tutorial
[stillshot]: https://pub.dartlang.org/packages/stillshot
[promoimage]: https://github.com/MikeMitterer/dart-sitegen/blob/master/lib/screenshot.jpg?raw=true
[video]: http://goo.gl/uUTg8s

