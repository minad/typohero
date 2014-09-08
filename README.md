# TypoHero

TypoHero has come to enhance your typography. There are no options, there is no documentation. He knows what you need.

~~~ ruby
require 'typohero'
TypoHero.enhance('Some text...')
TypoHero.truncate('Long text with tags...', max_words_or_separator)
TypoHero.strip_tags('Text with tags...')
~~~

![](https://raw.github.com/minad/typohero/master/hero.jpg)

## Features

* `TypoHero.enhance` -  Typography enhancer
  * Special character treatment for quotes, dashes and ellipsis
  * Widon't with Unicode non-breaking space
  * Skips special tags like `<script>`
  * Styling enhancements
    * Captial letters are wrapped in `<span class="caps">`
    * Initial quotes are wrapped in `<span class="quo">`
    * Ampersands are wrapped in `<span class="amp">`
  * Wrap hyphenated words in `<span class="nobr">`
  * LaTeX support
    * Some LaTeX commands are replaced by their Unicode counterpart
    * Mathjax code is skipped
* `TypoHero.truncate` - Truncate which ensures that all tags are closed correctly
  * Supports maximum number of words and/or separator `String`/`Regexp`
* `TypoHero.strip_tags` - Strip tags from content, keep only text
* All methods keeps the string `html_safe?`

## Why?

There is already SmartyPants, RubyPants, Typogruby, Typogrify, Fast-Aleck? So why?!

* It is simpler, faster and more reliable than the others
* More features
* And I like regular expressions :)

But why not improve the existing libraries?

* SmartyPants is Perl
* RubyPants is good but too much of a direct Perl port
* Typogruby has nice features but the implementation seems more like a hack
* Typogrify is Python
* Fast-Aleck is C, but I don't want to use C since Ruby is already a perfect text processing language!

## Similar libraries

[Smartypants (Perl)](http://daringfireball.net/projects/smartypants/),
[Typogrify (Python)](https://github.com/mintchaos/typogrify),
[Typography-Helper (Ruby)](https://code.google.com/p/typography-helper/),
[RubyPants (Ruby)](http://chneukirchen.org/repos/rubypants/),
[Tyogruby (Ruby)](http://avdgaag.github.io/typogruby/),
[Typography (Ruby)](https://github.com/fxposter/typography),
[Typographer (Ruby)](https://github.com/Slotos/typographer),
[Typogrify (Ruby)](http://rubygems.org/gems/typogrify),
[Typogrowth (Ruby)](https://github.com/mudasobwa/typogrowth),
[Richtypo.js (Javascript)](https://github.com/sapegin/richtypo.js)
...

## License

~~~
The MIT License

Copyright (c) 2014 Daniel Mendler

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
~~~
