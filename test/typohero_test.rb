# -*- coding: utf-8 -*-
require 'minitest/autorun'
require 'typohero'

class TypoHeroTest < Minitest::Test
  def assert_enhance(str, orig)
    # todo test recursive
    a = TypoHero.enhance(str)
    #b = TypoHero.enhance(a)
    #assert_equal a, b
    #c = Typogruby.improve(str)
    #puts "\nInput:     #{str}\nTypogruby: #{c}\nTypoHero:      #{a}\n" if a != c
    orig = orig.gsub('&nbsp;', "\u00a0")
    orig.gsub!('&#8211;', "\u2013")
    orig.gsub!('&#8230;', "\u2026")
    orig.gsub!('&#8220;', "\u201C")
    orig.gsub!('&#8221;', "\u201D")
    orig.gsub!('&#8216;', "\u2018")
    orig.gsub!('&#8217;', "\u2019")
    assert_equal orig, a
  end

  def test_verbatim
    assert_enhance "foo!", "foo!"
    assert_enhance "<div>This is html</div>", "<div>This is&nbsp;html</div>"
    assert_enhance "<div>This is html with <crap </div> tags>", "<div>This is html with <crap </div> tags>"
    assert_enhance %q{
multiline

<b>html</b>

code

}, %q{
multiline

<b>html</b>&nbsp;code

}
  end

  def test_excluded
    assert_enhance "<script>'hello'</script>", "<script>'hello'</script>"
    assert_enhance "<!-- <a>'hello'</a> -->", "<!-- <a>'hello'</a> -->"
    assert_enhance "<![CDATA[<a>'hello'</a>]]>", "<![CDATA[<a>'hello'</a>]]>"
  end

  def test_quotes
    assert_enhance '"A first example"', '<span class="dquo">&#8220;</span>A first&nbsp;example&#8221;'
    assert_enhance '"A first "nested" example"',
                    '<span class="dquo">&#8220;</span>A first &#8220;nested&#8221;&nbsp;example&#8221;'

    assert_enhance '".', '&#8221;.'
    assert_enhance '"a', '<span class="dquo">&#8220;</span>a'

    assert_enhance "'.", '&#8217;.'
    assert_enhance "'a", '<span class="quo">&#8216;</span>a'

    assert_enhance %{<p>He said, "'Quoted' words in a larger quote."</p>},
    '<p>He said, &#8220;&#8216;Quoted&#8217; words in a larger&nbsp;quote.&#8221;</p>'

    assert_enhance %{"I like the 70's"}, '<span class="dquo">&#8220;</span>I like the&nbsp;70&#8217;s&#8221;'
    assert_enhance %{"I like the '70s"}, '<span class="dquo">&#8220;</span>I like the&nbsp;&#8217;70s&#8221;'
    assert_enhance %{"I like the '70!"}, '<span class="dquo">&#8220;</span>I like the&nbsp;&#8216;70!&#8221;'

    assert_enhance 'pre"post', 'pre&#8221;post'
    assert_enhance 'pre "post', 'pre&nbsp;&#8220;post'
    assert_enhance 'pre&nbsp;"post', 'pre&nbsp;&#8220;post'
    assert_enhance 'pre--"post', 'pre&nbsp;&#8211;&nbsp;&#8220;post'
    assert_enhance 'pre--"!', 'pre&nbsp;&#8211;&nbsp;&#8221;!'

    assert_enhance "pre'post", 'pre&#8217;post'
    assert_enhance "pre 'post", 'pre&nbsp;&#8216;post'
    assert_enhance "pre&nbsp;'post", 'pre&nbsp;&#8216;post'
    assert_enhance "pre--'post", 'pre&nbsp;&#8211;&nbsp;&#8216;post'
    assert_enhance "pre--'!", 'pre&nbsp;&#8211;&nbsp;&#8217;!'

    assert_enhance "<b>'</b>", '<b><span class="quo">&#8216;</span></b>'
    assert_enhance "foo<b>'</b>", "foo<b>&#8217;</b>"

    assert_enhance '<b>"</b>', '<b><span class="dquo">&#8220;</span></b>'
    assert_enhance 'foo<b>"</b>', "foo<b>&#8221;</b>"
  end

  def test_dashes
    assert_enhance "foo--bar", 'foo&nbsp;&#8211;&nbsp;bar'
    assert_enhance "foo - bar", 'foo&nbsp;&#8211;&nbsp;bar'
    assert_enhance "foo---bar", "foo\u202F\u2014\u202Fbar"
  end

  def test_ellipses
    assert_enhance "foo..bar", 'foo..bar'
    assert_enhance "foo...bar", 'foo&#8230;bar'
    assert_enhance "foo....bar", 'foo&#8230;.bar'

    assert_enhance "foo. . ..bar", 'foo&#8230;.bar'
    assert_enhance "foo. . ...bar", 'foo&#8230;..bar'
    assert_enhance "foo. . ....bar", 'foo&#8230;&#8230;bar'
  end

  def test_backticks
    assert_enhance "pre``post", 'pre&#8220;post'
    assert_enhance "pre ``post", 'pre&nbsp;&#8220;post'
    assert_enhance "pre&nbsp;``post", 'pre&nbsp;&#8220;post'
    assert_enhance "pre--``post", 'pre&nbsp;&#8211;&nbsp;&#8220;post'
    assert_enhance "pre--``!", 'pre&nbsp;&#8211;&nbsp;&#8220;!'

    assert_enhance "pre''post", 'pre&#8221;post'
    assert_enhance "pre ''post", 'pre&nbsp;&#8221;post'
    assert_enhance "pre&nbsp;''post", 'pre&nbsp;&#8221;post'
    assert_enhance "pre--''post", 'pre&nbsp;&#8211;&nbsp;&#8221;post'
    assert_enhance "pre--''!", 'pre&nbsp;&#8211;&nbsp;&#8221;!'
  end

  def test_single_backticks
    assert_enhance "`foo'", '<span class="quo">&#8216;</span>foo&#8217;'

    assert_enhance "pre`post", 'pre&#8216;post'
    assert_enhance "pre `post", 'pre&nbsp;&#8216;post'
    assert_enhance "pre&nbsp;`post", 'pre&nbsp;&#8216;post'
    assert_enhance "pre--`post", 'pre&nbsp;&#8211;&nbsp;&#8216;post'
    assert_enhance "pre--`!", 'pre&nbsp;&#8211;&nbsp;&#8216;!'

    assert_enhance "pre'post", 'pre&#8217;post'
    assert_enhance "pre 'post", 'pre&nbsp;&#8216;post'
    assert_enhance "pre&nbsp;'post", 'pre&nbsp;&#8216;post'
    assert_enhance "pre--'post", 'pre&nbsp;&#8211;&nbsp;&#8216;post'
    assert_enhance "pre--'!", 'pre&nbsp;&#8211;&nbsp;&#8217;!'
  end

  def test_process_escapes
    assert_enhance %q{foo\bar}, "foo\\bar"
    assert_enhance %q{foo\\\bar}, "foo\\bar"
    assert_enhance %q{foo\\\\\bar}, "foo\\\\bar"
    assert_enhance %q{foo\...bar}, "foo...bar"
    assert_enhance %q{foo\.\.\.bar}, "foo...bar"

    assert_enhance %q{foo\'bar}, "foo'bar"
    assert_enhance %q{foo\"bar}, "foo\"bar"
    assert_enhance %q{foo\-bar}, "foo-bar"
    assert_enhance %q{foo\`bar}, "foo`bar"
    assert_enhance %q{foo\,,}, "foo,,"

    assert_enhance %q{foo\#bar}, "foo\\#bar"
    assert_enhance %q{foo\*bar}, "foo\\*bar"
    assert_enhance %q{foo\&bar}, "foo\\&bar"
    assert_enhance %q{foo\\\theta}, "foo\\theta"
  end

  def test_should_replace_amps
    assert_enhance 'One & two', 'One <span class="amp">&amp;</span>&nbsp;two'
    assert_enhance 'One &amp; two', 'One <span class="amp">&amp;</span>&nbsp;two'
    assert_enhance 'One &#38; two', 'One <span class="amp">&amp;</span>&nbsp;two'
    assert_enhance 'One&nbsp;&amp;&nbsp;two', 'One&nbsp;<span class="amp">&amp;</span>&nbsp;two'
  end

  def test_should_ignore_special_amps
    assert_enhance 'One <span class="amp">&amp;</span> two', 'One <span class="amp">&amp;</span>&nbsp;two'
    assert_enhance '&ldquo;this&rdquo; & <a href="/?that&amp;test">that</a>', '<span class="dquo">&#8220;</span>this&#8221; <span class="amp">&amp;</span>&nbsp;<a href="/?that&amp;test">that</a>'
  end

  def test_should_replace_caps
    assert_enhance "A message from KU", 'A message from&nbsp;<span class="caps">KU</span>'
    assert_enhance 'Replace text <a href=".">IN</a> tags', 'Replace text <a href="."><span class="caps">IN</span></a>&nbsp;tags'
    assert_enhance 'Replace text <i>IN</i> tags', 'Replace text <i><span class="caps">IN</span></i>&nbsp;tags'
    assert_enhance 'AB, CD, EF', '<span class="caps">AB</span>, <span class="caps">CD</span>,&nbsp;<span class="caps">EF</span>'
  end

  def test_should_ignore_special_case_caps
    assert_enhance 'It should ignore just numbers like 1234.', 'It should ignore just numbers like&nbsp;1234.'
    assert_enhance "<pre>CAPS</pre> more CAPS", '<pre>CAPS</pre> more&nbsp;<span class="caps">CAPS</span>'
    assert_enhance "<Pre>CAPS</PRE> with odd tag names CAPS", '<Pre>CAPS</PRE> with odd tag names&nbsp;<span class="caps">CAPS</span>'
    assert_enhance "A message from 2KU2 with digits", 'A message from <span class="caps">2KU2</span> with&nbsp;digits'
    assert_enhance "Dotted caps followed by spaces should never include them in the wrap D.O.T.   like so.", 'Dotted caps followed by spaces should never include them in the wrap <span class="caps">D.O.T.</span>   like&nbsp;so.'
    assert_enhance 'Caps in attributes (<span title="Example CAPS">example</span>) should be ignored', 'Caps in attributes (<span title="Example CAPS">example</span>) should be&nbsp;ignored'
    assert_enhance '<head><title>CAPS Example</title></head>', '<head><title>CAPS Example</title></head>'
  end

  def test_should_not_break_caps_with_apostrophes
    assert_enhance "JIMMY'S", '<span class="caps">JIMMY&#8217;S</span>'
    assert_enhance "<i>D.O.T.</i>HE34T<b>RFID</b>", '<i><span class="caps">D.O.T.</span></i><span class="caps">HE34T</span><b><span class="caps">RFID</span></b>'
  end

  def test_should_not_break_caps_with_ampersands
    assert_enhance "AT&T", '<span class="caps">AT&T</span>'
    assert_enhance "AT&amp;T", '<span class="caps">AT&amp;T</span>'
    assert_enhance "AT&#38;T", '<span class="caps">AT&amp;T</span>'
  end

  def test_should_prevent_widows
    assert_enhance 'A very simple test', 'A very simple&nbsp;test'
  end

  def test_should_not_change_single_word_items
    assert_enhance 'Test', 'Test'
    assert_enhance ' Test', ' Test'
    assert_enhance '<ul><li>Test</p></li><ul>', '<ul><li>Test</p></li><ul>'
    assert_enhance '<ul><li> Test</p></li><ul>', '<ul><li> Test</p></li><ul>'
    assert_enhance '<p>In a couple of paragraphs</p><p>paragraph two</p>', '<p>In a couple of&nbsp;paragraphs</p><p>paragraph&nbsp;two</p>'
    assert_enhance '<h1><a href="#">In a link inside a heading</i> </a></h1>', '<h1><a href="#">In a link inside a&nbsp;heading</i> </a></h1>'
    assert_enhance '<h1><a href="#">In a link</a> followed by other text</h1>', '<h1><a href="#">In a link</a> followed by other&nbsp;text</h1>'
  end

  def test_should_not_add_nbsp_before_another
    assert_enhance 'Sentence with one&nbsp;nbsp', 'Sentence with one&nbsp;nbsp'
  end

  def test_should_not_error_on_empty_html
    assert_enhance '<h1><a href="#"></a></h1>', '<h1><a href="#"></a></h1>'
  end

  def test_should_ignore_widows_in_special_tags
    assert_enhance '<div>Divs get love!</div>', '<div>Divs get&nbsp;love!</div>'
    assert_enhance '<pre>Neither do PREs</pre>', '<pre>Neither do PREs</pre>'
    assert_enhance '<textarea>nor text in textarea</textarea>', '<textarea>nor text in textarea</textarea>'
    assert_enhance "<script>\nreturn window;\n</script>", "<script>\nreturn window;\n</script>"
    assert_enhance '<div><p>But divs with paragraphs do!</p></div>', '<div><p>But divs with paragraphs&nbsp;do!</p></div>'
  end

  def test_widont
    code = %q{
<ul>
  <li>
    <a href="/contact/">Contact</a>
  </li>
</ul>}
    assert_enhance code, code
  end

  def test_should_replace_quotes
    assert_enhance '"With primes"', '<span class="dquo">&#8220;</span>With&nbsp;primes&#8221;'
    assert_enhance "'With single primes'", '<span class="quo">&#8216;</span>With single&nbsp;primes&#8217;'
    assert_enhance '<a href="#">"With primes and a link"</a>', '<a href="#"><span class="dquo">&#8220;</span>With primes and a&nbsp;link&#8221;</a>'
    assert_enhance '&#8220;With smartypanted quotes&#8221;', '<span class="dquo">&#8220;</span>With smartypanted&nbsp;quotes&#8221;'
    assert_enhance '&lsquo;With manual quotes&rsquo;', '<span class="quo">&#8216;</span>With manual&nbsp;quotes&#8217;'
  end

  def test_should_apply_all_filters
    assert_enhance '<h2>"Jayhawks" & KU fans act extremely obnoxiously</h2>', '<h2><span class="dquo">&#8220;</span>Jayhawks&#8221; <span class="amp">&amp;</span> <span class="caps">KU</span> fans act extremely&nbsp;obnoxiously</h2>'
  end

  def test_other_special
    assert_enhance ',,hello\'\'', "<span class=\"bdquo\">\u201E</span>hello&#8221;"
    assert_enhance '(tm)', "\u2122"
  end

  def test_primes
    assert_enhance "She's  6'2''", "She&#8217;s&nbsp;6\u20322\u2033"
    assert_enhance %{He said "Oslo coordinates are: 59°57'N 10°45'E" and there it is.}, "He said &#8220;Oslo coordinates are: 59°57\u2032N 10°45\u2032E&#8221; and there it&nbsp;is."
  end

  def test_ordinals
    assert_enhance 'I am the 1st', 'I am the&nbsp;1<sup>st</sup>'
  end

  def test_latex
    assert_enhance '\\textbackslash', '\\'
  end

  def test_nobr
    assert_enhance 'T-shirt', '<span class="nobr">T-shirt</span>'
  end

  def test_ignore_mathjax
    assert_enhance '$$\\approx$$ outside \\approx', "$$\\approx$$ outside&nbsp;\u2248"
    assert_enhance '\) $$\\approx$$ outside \\approx', "\\) $$\\approx$$ outside&nbsp;\u2248"
    assert_enhance '\] $$\\approx$$ outside \\approx', "\\] $$\\approx$$ outside&nbsp;\u2248"
    assert_enhance '\\(\\approx\\) outside \\approx', "\\(\\approx\\) outside&nbsp;\u2248"
    assert_enhance '\\[\\approx\\] outside \\approx', "\\[\\approx\\] outside&nbsp;\u2248"
    assert_enhance '<span>$</span>', '<span>$</span>'
    assert_enhance '<span>\\</span>', '<span>\\</span>'
  end

  def test_truncate
    assert_equal "<a>a <span>b\u2026</span></a>", TypoHero.truncate('<a>a <span>b c d</span> c</a>', 2)
    assert_equal "<a>a <span>b\u2026</span></a>", TypoHero.truncate('<a>a <span>b!?! c d</span> c</a>', 2)
    assert_equal "<a>a <!--comment--><span>b\u2026</span></a>", TypoHero.truncate('<a>a <!--comment--><span>b </span> c</a>', 2)
    assert_equal "<a>a <!--comment--><span>b\u2026</span></a>", TypoHero.truncate('<a>a <!--comment--><span>b!!! </span> c</a>', 2)
    assert_equal "<!--comment-->a <span>b\u2026</span>", TypoHero.truncate('<!--comment-->a <span>b </span>c', 2)
    assert_equal "<a>a <span><script>b</script> c\u2026</span></a>", TypoHero.truncate('<a>a <span><script>b</script> c d</span> c</a>', 2)
    assert_equal "<p>Lorem ipsum dolor sit amet.</p>", TypoHero.truncate("<p>Lorem ipsum dolor sit amet.</p>", 5)
    assert_equal "<p>Lorem ipsum\u2026</p>", TypoHero.truncate("<p>Lorem ipsum dolor sit amet.</p>", 5, 'dolor')
    assert_equal "<p>Lorem ipsum dolor\u2026</p>", TypoHero.truncate("<p>Lorem ipsum dolor<!--more--> sit amet.</p>", 5, 'more')
    assert_equal "<p>Lorem ipsum dolor\u2026</p>", TypoHero.truncate("<p>Lorem ipsum dolor<!--more--> sit amet.</p>", 5, '<!--more-->')
    assert_equal "<p>Lorem ipsum dolor\u2026</p>", TypoHero.truncate("<p>Lorem ipsum dolor<!--more--> sit amet.</p>", 5, /more/)
    assert_equal "<p><span>Lorem ipsum dolor\u2026</span></p>", TypoHero.truncate("<p><span>Lorem ipsum dolor</span> sit amet.</p>", 5, '</span>')
    assert_equal "<p>Lorem ipsum dolor\u2026</p>", TypoHero.truncate("<p>Lorem ipsum dolor<span class=\"more\"> sit amet.</span></p>", 5, 'more')
    assert_equal "<p>Lorem ipsum dolor\u2026</p>", TypoHero.truncate("<p>Lorem ipsum dolor<span class=\"more\"> sit amet.</span></p>", 'more', 10)
    assert_equal "<p>Lorem ipsum\u2026</p>", TypoHero.truncate("<p>Lorem ipsum dolor<span class=\"more\"> sit amet.</span></p>", 'more', 2)
  end

  def test_strip_tags
    assert_equal 'a b c d e', TypoHero.strip_tags('<a>a <span>b c d</span> e</a>')
    assert_equal 'a  c d e', TypoHero.strip_tags('<a>a <span><script>b</script> c d</span> e</a>')
    assert_equal 'a   \(latex\) text', TypoHero.strip_tags('a <script>\(a b c\)</script><a> <test> \(latex\) text')
  end
end
