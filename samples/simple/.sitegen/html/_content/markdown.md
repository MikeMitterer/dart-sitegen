# Anything above the '~~~' line is interpreted as YAML,
# and is used to set variables you can access from your template tags.
# This is an example of a YAML comment which will be completely ignored.

# A basic variable definition
title: Markdown2

# A list of strings. Surrounding your strings in quotes is optional,
# but some may require it so they  don't interfere with YAML syntax.
default_vars:
  - "`title`: post title, automatically set to name of markdown file if left blank"
  - "`_site`: site.yaml values"
  - "`_date`: post 'last modified' date"
  - "`_content`: post content (only accessible from templates, not markdown)"

# Alternate List Syntax
authors: [hallo,foo,bar,baz]

# A list of Dictionaries
links:
  - name: Dart
    url: https://dartlang.org
  - name: Pub
    url: https://pub.dartlang.org
  # alternate inline-dict style:
  - {name: Google, url: http://google.com}
  - {name: Github, url: http://github.com}

# You can even embed markdown in your YAML strings if you want (as long as you use the values
# in the markdown file itself -- markdown injected into html templates will not get evaluated).
tags:
  - "[SiteGen][sitegen]"
  - "[Markdown][markdown]"
  - "[Mustache][mustache]"
  - "[YAML][yaml]"

# You can also override your 'date_format' setting from your site.yaml
# for each individual post
date_format: yMd

# And here we manually define the template we want to use.
# Note the lack of a file extension. This is to have compatibility
# with any template file-type, though mustache embedded in plain
# old HTML is the default. If no template is defined here, SiteGen
# will use the one listed for 'default_template' in your site.yaml

#template: info_page
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### {{title}} (Content)
#### Subheadline


3 `~`'s is the minimum for designating and separating a [YAML][yaml] block, but they can be extended longer -- all that matters
is that the tildes (`~`) are on their own line.

And anything beyond that gets interpreted as [Markdown][markdown]!

You can even use template tags in here, for any variables you set in in the top YAML block, or in your `site.yaml` file:

This post's title is: "{{ title }}"

This file was last modified on {{ _date }}

Link to [subpages](about/)

Note that variables beginning with an underscore designate *implicit* metadata added by __SiteGen__.

Some vars that are always available by default:

Image: ![Logo](assets/images/ios-desktop.png)

----
{{#_data.items}}
<li>
    {{name}}
    {{#if items}}
    <ul>
    {{> list}}
    </ul>
    {{/if items}}
</li>
{{/_data.items}}

----    

{{#default_vars}}
    {{.}}
{{/default_vars}}

You can see all the vars you can use if you start __SiteGen__ with `--loglevel debug`.   

And as you can see, you can also use mustache logic to iterate through yaml maps and lists:

{{#links}}
[{{name}}]({{url}})   
{{/links}}

{{#tags}}
* {{.}}
{{/tags}}

{{#authors}}
- {{.}}
{{/authors}}

Note how you need to use a `.` to access a list item, but can access map/dict keys directly.

You can of course disable these markdown templating features by setting `markdown_templating: true` in your site.yaml file.
Same ideas apply when writing your actual HTML templates. See [mustache's docs][mustache] for more templating info.

[yaml]: http://rhnh.net/2011/01/31/yaml-tutorial
[markdown]: http://daringfireball.net/projects/markdown/syntax
[mustache]: http://mustache.github.io/mustache.5.html
[sitegen]: https://github.com/MikeMitterer/dart-sitegen
