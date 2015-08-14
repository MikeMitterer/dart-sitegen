# SiteGen 
Static site generator. Includes a webserver, sass + autoprefix support

### New
`--ip` option - now you can set the IP the server listens to. (Defaults to 127.0.0.1)  
Helps to test your site from within a VM for example. 

With extra assets-folder and partials-support. A static site generator in [Dart][dart], webserver included.  
You can write your pages in HTML or [Markdown][markdown]. For Templates [Mustache][mustache] is supported.
  
A webserver for a quick review is included. On Mac you also get automatic page refresh. On other 
platforms you could try [LivePage][livepage] chrome extension for maximum productivity.  

Before you read on - check out this video:

[![ScreenShot][promoimage]](http://goo.gl/uUTg8s)

[Here][example] you can see a typical site structure.  

```
├── .sitegen
│   ├── refreshChromium-1.0.applescript
│   ├── html
│   │   ├── _assets
│   │   │   └── demo.scss
│   │   │
│   │   ├── _content
│   │   │   ├── about
│   │   │   │   └── index.html
│   │   │   ├── index.html
│   │   │   ├── markdown.md
│   │   │   ├── piratenames.json
│   │   │   └── xtreme.html
│   │   │
│   │   ├── _data
│   │   │   ├── xmen.yaml
│   │   │   └── families.json
│   │   │
│   │   └── _templates
│   │       ├── default.html
│   │       └── info_page.html
│   │   
│   └── site.yaml (Optional!)
│
└── web
    ├── about
    │   ├── index.html
    │   └── packages -> ../../packages
    │
    ├── index.html
    ├── main.dart
    ├── markdown.html
    ├── packages -> ../packages
    ├── piratenames.json
    │
    ├── styles
    │   ├── main.css
    │   ├── main.scss
    │   └── packages -> ../../packages
    │
    └── xtreme.html
```

**.sitegen**: This is where your (optional) site.yaml lives  
This folder is also used to store autgenerated scripts - in the case above you can see
the script to refresh Chromium on Mac.

**.sitegen/html/_content**: This is where **SiteGen** will look for your files to generate the site from.
The following file-formats are supported:

- .md
- .markdown
- .dart
- .js
- .json
- .html
- .scss
- .css

**.sitegen/html/_data**: [optional] This is the place where you can store your data-files.  
The following file-formats are supported:

- .yaml
- .json

**SiteGen** injects your data into a global _data variable.
Here is a sample how to use such data:
  
```html
<ul>
    {{#_data.xmen}}
    <li>{{.}}</li>
    {{/_data.xmen}}
</ul>
```

**.sitegen/html/_assets**: [optional] Additional assets that you don't want to have in _content. For example .scss 
or .jpg files.

**.sitegen/html/_templates**: The directory containing your HTML+Mustache templates.

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

- content_dir: .sitegen/html/_content 
- template_dir: .sitegen/html/_templates
- data_dir: .sitegen/html/_data
- partials_dir: .sitegen/html/_partials
- assets_dir: .sitegen/html/_assets
- output_dir: web
- workspace: .
- date_format: dd.MM.yyyy
- yaml_delimeter: ~~~
- use_markdown: true
- default_template: default.html
- sasscompiler: sassc
- usesass: true
- autoprefixer: true
- browser: Chromium
- talktome: true (on OSX, false on all the other OSs)
- watchfolder1, watchfolder2 and watchfolder3

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
    
    
## Partials 
**Optional**  
Files / Directories in your _partials-Folder will be translated into partials-names.  
For example: _partials/category/house.md translates into {{>category.house}}  
A partial can be either a .md or a .html file

You can also use partials in the files yaml block:
```yaml
template: default.html    
dart: ->usage.badge.dart  
~~~  
```


    
## SASS
If SiteGen finds a .scss file in your output dir (web) it compiles it to the corresponding .css file.      
Install instruction for SASS can be found [here][installsass]  
In short it's `gem install sass` and `gem install sassc`  

You can turn off SASS either with `--no-usesass` or with the appropriate setting in site.yaml 

## Autoprefixer
After compiling .SCSS to .CSS SiteGen calls autoprefixer <yourcss>  
Install autoprefixer with `npm install --global autoprefixer`

You can turn off Autoprefixer either with `--no-useapfx` or with the appropriate setting in site.yaml 
    
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
    -s, --settings         Prints settings
    -h, --help             Shows this message
    -g, --generate         Generate site
    -c, --generatecss      Generate CSS (compile SCSS2CSS)
    -w, --watch            Observes SRC-dir
    -x, --watchandserve    Shortcut to watch and serve
    -i, --init             Initializes your site
                           (not combinable with other options)

        --serve            Serves your site
        --[no-]usesass     Enables / disables SASS to CSS compiler
                           (defaults to on)

        --[no-]useapfx     Enables / disables Autoprefixer
                           (defaults to on)

        --[no-]talktome    Enables / disables Speek-Output
                           (defaults to on)

        --ip               Sets the IP-Address to listen on
                           (defaults to "127.0.0.1")

        --port             Sets the port to listen on
                           (defaults to "8000")

        --docroot          Document root
                           (defaults to "web")

    -v, --loglevel         Sets the appropriate loglevel
                           [info, debug, warning]

Sample:

    'Generates all basic files and folders:                'sitegen -i'
    'Observes the default dirs and serves the web-folder:  'sitegen -w --serve'
    'Observes the default dirs and serves the web-folder:  'sitegen -x'
    'Generates the static site in your 'web-folder':       'sitegen -g'
```

Go to your project root (this is where your pubspec.yaml is) and type:

    sitegen -i
    
This creates a basic file structure for you.     

Now type

    sitegen -w --serve
    
This servers your files under http://localhost:8000/    
        
If you are using Chromium on Mac you will get a automatic page refresh for free!
 
Now play with sitegen and watch my screencast...

Check out the [sample!][sample]

## Hints
- Just serve a local dir on port 8000 without generating something:  
    `sitegen --serve --docroot .`
    
- Sitegen observes automatically it's basefolders like content, web aso. but if
    you want additional folders that should be observed so that sitegen automatically regenerates it's
    file - set watchfolder[1-3] in you site.yaml
    
- Test your App with Chrome and use sitegen as server (MAC + Linux only)  
    `pub build && cd build/web && sitegen --serve --port 9000 --docroot . || cd -`
    
    *Explanation:*  
    Runs "pub build" - if this runs without errors cd to "build/web"
    In "build/web" run sitegen as server on port 9000 and set docroot to . (current dir (default would be "web"))  
    || means if the prev command ends with an error (Ctrl + C to cancel sitegen)   
    jump back where you came from. You should be back in your base folder (where your pubspec.yaml is)
    
 

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
[promoimage]: https://github.com/MikeMitterer/dart-sitegen/blob/master/assets/screenshot.jpg?raw=true
[video]: http://goo.gl/uUTg8s
[installsass]: http://sass-lang.com/install
[sample]: https://github.com/MikeMitterer/dart-sitegen/tree/master/example/simple

