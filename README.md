
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

.sitegen: This is where your site.yaml lives  
This folder is also used to store autgenerated scripts - in the case above you can see
the script to refresh Chromium on Mac

html/_content: This is where **SiteGen** will look for your files to generate the site from.
The following file-formats are supported:

- .md
- .markdown
- .dart
- .js
- .json
- .html
- .scss
- .css
                    
html/_templates: The directory containing your HTML+Mustache templates.

web: Following Dart conventions - this is your default output directory.

## site.yaml
**Optional** [YAML][yaml] file that stores your global values and config options.
Values set here can be accessed from all templates and markdown files.

```
site_options:
  author: Mike Mitterer
```

Can be used in you template (default.html) as
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



### Features and bugs
Please file feature requests and bugs at the [issue tracker][tracker].

### Thanks
I want to thank "Enrique Gavidia" for his [stillshot][stillshot] package that I used as basis for **SiteGen** 

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
or **star** this repo here on GitHub

[dart]: https://www.dartlang.org/
[tracker]: https://github.com/MikeMitterer/dart-sitegen/issues
[markdown]: http://daringfireball.net/projects/markdown/syntax
[mustache]: http://mustache.github.io/mustache.5.html
[livepage]: https://chrome.google.com/webstore/detail/livepage/pilnojpmdoofaelbinaeodfpjheijkbh
[example]: https://github.com/MikeMitterer/dart-sitegen/tree/master/examples/simple
[yaml]: http://rhnh.net/2011/01/31/yaml-tutorial
[stillshot]: https://pub.dartlang.org/packages/stillshot
[promoimage]: https://github.com/MikeMitterer/dart-sitegen/blob/master/assets/screenshot.jpg?raw=true
[video]: http://goo.gl/uUTg8s

