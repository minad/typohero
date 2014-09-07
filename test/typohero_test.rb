# -*- coding: utf-8 -*-
require 'minitest/autorun'
require 'typohero'

class TypoHeroTest < Minitest::Test
  def assert_typo(str, orig)
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
    assert_typo "foo!", "foo!"
    assert_typo "<div>This is html</div>", "<div>This is&nbsp;html</div>"
    assert_typo "<div>This is html with <crap </div> tags>", "<div>This is html with <crap </div> tags>"
    assert_typo %q{
multiline

<b>html</b>

code

}, %q{
multiline

<b>html</b>&nbsp;code

}
  end

  def test_excluded
    assert_typo "<script>'hello'</script>", "<script>'hello'</script>"
    assert_typo "<!-- <a>'hello'</a> -->", "<!-- <a>'hello'</a> -->"
  end

  def test_quotes
    assert_typo '"A first example"', '<span class="dquo">&#8220;</span>A first&nbsp;example&#8221;'
    assert_typo '"A first "nested" example"',
                    '<span class="dquo">&#8220;</span>A first &#8220;nested&#8221;&nbsp;example&#8221;'

    assert_typo '".', '&#8221;.'
    assert_typo '"a', '<span class="dquo">&#8220;</span>a'

    assert_typo "'.", '&#8217;.'
    assert_typo "'a", '<span class="quo">&#8216;</span>a'

    assert_typo %{<p>He said, "'Quoted' words in a larger quote."</p>},
    '<p>He said, &#8220;&#8216;Quoted&#8217; words in a larger&nbsp;quote.&#8221;</p>'

    assert_typo %{"I like the 70's"}, '<span class="dquo">&#8220;</span>I like the&nbsp;70&#8217;s&#8221;'
    assert_typo %{"I like the '70s"}, '<span class="dquo">&#8220;</span>I like the&nbsp;&#8217;70s&#8221;'
    assert_typo %{"I like the '70!"}, '<span class="dquo">&#8220;</span>I like the&nbsp;&#8216;70!&#8221;'

    assert_typo 'pre"post', 'pre&#8221;post'
    assert_typo 'pre "post', 'pre&nbsp;&#8220;post'
    assert_typo 'pre&nbsp;"post', 'pre&nbsp;&#8220;post'
    assert_typo 'pre--"post', 'pre &#8211;&nbsp;&#8220;post'
    assert_typo 'pre--"!', 'pre &#8211;&nbsp;&#8221;!'

    assert_typo "pre'post", 'pre&#8217;post'
    assert_typo "pre 'post", 'pre&nbsp;&#8216;post'
    assert_typo "pre&nbsp;'post", 'pre&nbsp;&#8216;post'
    assert_typo "pre--'post", 'pre &#8211;&nbsp;&#8216;post'
    assert_typo "pre--'!", 'pre &#8211;&nbsp;&#8217;!'

    assert_typo "<b>'</b>", '<b><span class="quo">&#8216;</span></b>'
    assert_typo "foo<b>'</b>", "foo<b>&#8217;</b>"

    assert_typo '<b>"</b>', '<b><span class="dquo">&#8220;</span></b>'
    assert_typo 'foo<b>"</b>', "foo<b>&#8221;</b>"
  end

  def test_dashes
    assert_typo "foo--bar", 'foo &#8211;&nbsp;bar'
    assert_typo "foo---bar", "foo\u2009\u2014&nbsp;bar"
  end

  def test_ellipses
    assert_typo "foo..bar", 'foo..bar'
    assert_typo "foo...bar", 'foo&#8230;bar'
    assert_typo "foo....bar", 'foo&#8230;.bar'

    assert_typo "foo. . ..bar", 'foo&#8230;.bar'
    assert_typo "foo. . ...bar", 'foo&#8230;..bar'
    assert_typo "foo. . ....bar", 'foo&#8230;&#8230;bar'
  end

  def test_backticks
    assert_typo "pre``post", 'pre&#8220;post'
    assert_typo "pre ``post", 'pre&nbsp;&#8220;post'
    assert_typo "pre&nbsp;``post", 'pre&nbsp;&#8220;post'
    assert_typo "pre--``post", 'pre &#8211;&nbsp;&#8220;post'
    assert_typo "pre--``!", 'pre &#8211;&nbsp;&#8220;!'

    assert_typo "pre''post", 'pre&#8221;post'
    assert_typo "pre ''post", 'pre&nbsp;&#8221;post'
    assert_typo "pre&nbsp;''post", 'pre&nbsp;&#8221;post'
    assert_typo "pre--''post", 'pre &#8211;&nbsp;&#8221;post'
    assert_typo "pre--''!", 'pre &#8211;&nbsp;&#8221;!'
  end

  def test_single_backticks
    assert_typo "`foo'", '<span class="quo">&#8216;</span>foo&#8217;'

    assert_typo "pre`post", 'pre&#8216;post'
    assert_typo "pre `post", 'pre&nbsp;&#8216;post'
    assert_typo "pre&nbsp;`post", 'pre&nbsp;&#8216;post'
    assert_typo "pre--`post", 'pre &#8211;&nbsp;&#8216;post'
    assert_typo "pre--`!", 'pre &#8211;&nbsp;&#8216;!'

    assert_typo "pre'post", 'pre&#8217;post'
    assert_typo "pre 'post", 'pre&nbsp;&#8216;post'
    assert_typo "pre&nbsp;'post", 'pre&nbsp;&#8216;post'
    assert_typo "pre--'post", 'pre &#8211;&nbsp;&#8216;post'
    assert_typo "pre--'!", 'pre &#8211;&nbsp;&#8217;!'
  end

  def test_process_escapes
    assert_typo %q{foo\bar}, "foo\\bar"
    assert_typo %q{foo\\\bar}, "foo\\bar"
    assert_typo %q{foo\\\\\bar}, "foo\\\\bar"
    assert_typo %q{foo\...bar}, "foo...bar"
    assert_typo %q{foo\.\.\.bar}, "foo...bar"

    assert_typo %q{foo\'bar}, "foo'bar"
    assert_typo %q{foo\"bar}, "foo\"bar"
    assert_typo %q{foo\-bar}, "foo-bar"
    assert_typo %q{foo\`bar}, "foo`bar"
    assert_typo %q{foo\,,}, "foo,,"

    assert_typo %q{foo\#bar}, "foo\\#bar"
    assert_typo %q{foo\*bar}, "foo\\*bar"
    assert_typo %q{foo\&bar}, "foo\\&bar"
    assert_typo %q{foo\\\theta}, "foo\\theta"
  end

  def test_should_replace_amps
    assert_typo 'One & two', 'One <span class="amp">&amp;</span>&nbsp;two'
    assert_typo 'One &amp; two', 'One <span class="amp">&amp;</span>&nbsp;two'
    assert_typo 'One &#38; two', 'One <span class="amp">&amp;</span>&nbsp;two'
    assert_typo 'One&nbsp;&amp;&nbsp;two', 'One&nbsp;<span class="amp">&amp;</span>&nbsp;two'
  end

  def test_should_ignore_special_amps
    assert_typo 'One <span class="amp">&amp;</span> two', 'One <span class="amp">&amp;</span>&nbsp;two'
    assert_typo '&ldquo;this&rdquo; & <a href="/?that&amp;test">that</a>', '<span class="dquo">&#8220;</span>this&#8221; <span class="amp">&amp;</span>&nbsp;<a href="/?that&amp;test">that</a>'
  end

  def test_should_replace_caps
    assert_typo "A message from KU", 'A message from&nbsp;<span class="caps">KU</span>'
    assert_typo 'Replace text <a href=".">IN</a> tags', 'Replace text <a href="."><span class="caps">IN</span></a>&nbsp;tags'
    assert_typo 'Replace text <i>IN</i> tags', 'Replace text <i><span class="caps">IN</span></i>&nbsp;tags'
  end

  def test_should_ignore_special_case_caps
    assert_typo 'It should ignore just numbers like 1234.', 'It should ignore just numbers like&nbsp;1234.'
    assert_typo "<pre>CAPS</pre> more CAPS", '<pre>CAPS</pre> more&nbsp;<span class="caps">CAPS</span>'
    assert_typo "<Pre>CAPS</PRE> with odd tag names CAPS", '<Pre>CAPS</PRE> with odd tag names&nbsp;<span class="caps">CAPS</span>'
    assert_typo "A message from 2KU2 with digits", 'A message from <span class="caps">2KU2</span> with&nbsp;digits'
    assert_typo "Dotted caps followed by spaces should never include them in the wrap D.O.T.   like so.", 'Dotted caps followed by spaces should never include them in the wrap <span class="caps">D.O.T.</span>   like&nbsp;so.'
    assert_typo 'Caps in attributes (<span title="Example CAPS">example</span>) should be ignored', 'Caps in attributes (<span title="Example CAPS">example</span>) should be&nbsp;ignored'
    assert_typo '<head><title>CAPS Example</title></head>', '<head><title>CAPS Example</title></head>'
  end

  def test_should_not_break_caps_with_apostrophes
    assert_typo "JIMMY'S", '<span class="caps">JIMMY&#8217;S</span>'
    assert_typo "<i>D.O.T.</i>HE34T<b>RFID</b>", '<i><span class="caps">D.O.T.</span></i><span class="caps">HE34T</span><b><span class="caps">RFID</span></b>'
  end

  def test_should_not_break_caps_with_ampersands
    assert_typo "AT&T", '<span class="caps">AT&T</span>'
    assert_typo "AT&amp;T", '<span class="caps">AT&amp;T</span>'
    assert_typo "AT&#38;T", '<span class="caps">AT&amp;T</span>'
  end

  def test_should_prevent_widows
    assert_typo 'A very simple test', 'A very simple&nbsp;test'
  end

  def test_should_not_change_single_word_items
    assert_typo 'Test', 'Test'
    assert_typo ' Test', ' Test'
    assert_typo '<ul><li>Test</p></li><ul>', '<ul><li>Test</p></li><ul>'
    assert_typo '<ul><li> Test</p></li><ul>', '<ul><li> Test</p></li><ul>'
    assert_typo '<p>In a couple of paragraphs</p><p>paragraph two</p>', '<p>In a couple of&nbsp;paragraphs</p><p>paragraph&nbsp;two</p>'
    assert_typo '<h1><a href="#">In a link inside a heading</i> </a></h1>', '<h1><a href="#">In a link inside a&nbsp;heading</i> </a></h1>'
    assert_typo '<h1><a href="#">In a link</a> followed by other text</h1>', '<h1><a href="#">In a link</a> followed by other&nbsp;text</h1>'
  end

  def test_should_not_add_nbsp_before_another
    assert_typo 'Sentence with one&nbsp;nbsp', 'Sentence with one&nbsp;nbsp'
  end

  def test_should_not_error_on_empty_html
    assert_typo '<h1><a href="#"></a></h1>', '<h1><a href="#"></a></h1>'
  end

  def test_should_ignore_widows_in_special_tags
    assert_typo '<div>Divs get love!</div>', '<div>Divs get&nbsp;love!</div>'
    assert_typo '<pre>Neither do PREs</pre>', '<pre>Neither do PREs</pre>'
    assert_typo '<textarea>nor text in textarea</textarea>', '<textarea>nor text in textarea</textarea>'
    assert_typo "<script>\nreturn window;\n</script>", "<script>\nreturn window;\n</script>"
    assert_typo '<div><p>But divs with paragraphs do!</p></div>', '<div><p>But divs with paragraphs&nbsp;do!</p></div>'
  end

  def test_widont
    code = %q{
<ul>
  <li>
    <a href="/contact/">Contact</a>
  </li>
</ul>}
    assert_typo code, code
  end

  def test_should_replace_quotes
    assert_typo '"With primes"', '<span class="dquo">&#8220;</span>With&nbsp;primes&#8221;'
    assert_typo "'With single primes'", '<span class="quo">&#8216;</span>With single&nbsp;primes&#8217;'
    assert_typo '<a href="#">"With primes and a link"</a>', '<a href="#"><span class="dquo">&#8220;</span>With primes and a&nbsp;link&#8221;</a>'
    assert_typo '&#8220;With smartypanted quotes&#8221;', '<span class="dquo">&#8220;</span>With smartypanted&nbsp;quotes&#8221;'
    assert_typo '&lsquo;With manual quotes&rsquo;', '<span class="quo">&#8216;</span>With manual&nbsp;quotes&#8217;'
  end

  def test_should_apply_all_filters
    assert_typo '<h2>"Jayhawks" & KU fans act extremely obnoxiously</h2>', '<h2><span class="dquo">&#8220;</span>Jayhawks&#8221; <span class="amp">&amp;</span> <span class="caps">KU</span> fans act extremely&nbsp;obnoxiously</h2>'
  end

  def test_other_special
    assert_typo ',,hello\'\'', "<span class=\"bdquo\">\u201E</span>hello&#8221;"
    assert_typo '(tm)', "\u2122"
  end

  def test_primes
    assert_typo "She's  6'2''", "She&#8217;s&nbsp;6\u20322\u2033"
  end

  def test_ordinals
    assert_typo 'I am the 1st', 'I am the&nbsp;1<sup>st</sup>'
  end

  def test_latex
    assert_typo '\\textbackslash', '\\'
  end

  def test_ignore_mathjax
    assert_typo '$$\\approx$$ outside \\approx', "$$\\approx$$ outside&nbsp;\u2248"
    assert_typo '\) $$\\approx$$ outside \\approx', "\\) $$\\approx$$ outside&nbsp;\u2248"
    assert_typo '\] $$\\approx$$ outside \\approx', "\\] $$\\approx$$ outside&nbsp;\u2248"
    assert_typo '\\(\\approx\\) outside \\approx', "\\(\\approx\\) outside&nbsp;\u2248"
    assert_typo '\\[\\approx\\] outside \\approx', "\\[\\approx\\] outside&nbsp;\u2248"
    assert_typo '<span>$</span>', '<span>$</span>'
    assert_typo '<span>\\</span>', '<span>\\</span>'
  end

  def test_truncate
    assert_equal "<a>a <span>b\u2026</span></a>", TypoHero.truncate('<a>a <span>b c d</span> c</a>', 2)
    assert_equal "<a>a <span>b\u2026</span></a>", TypoHero.truncate('<a>a <span>b!?! c d</span> c</a>', 2)
    assert_equal "<a>a <!--comment--><span>b\u2026</span></a>", TypoHero.truncate('<a>a <!--comment--><span>b </span> c</a>', 2)
    assert_equal "<a>a <!--comment--><span>b\u2026</span></a>", TypoHero.truncate('<a>a <!--comment--><span>b!!! </span> c</a>', 2)
    assert_equal "<!--comment-->a <span>b\u2026</span>", TypoHero.truncate('<!--comment-->a <span>b </span>c', 2)
    assert_equal "<a>a <span><script>b</script> c\u2026</span></a>", TypoHero.truncate('<a>a <span><script>b</script> c d</span> c</a>', 2)
    assert_equal "<p>Lorem ipsum dolor sit amet.</p>", TypoHero.truncate("<p>Lorem ipsum dolor sit amet.</p>", 5)
  end

  def test_strip_tags
    assert_equal 'a b c d e', TypoHero.strip_tags('<a>a <span>b c d</span> e</a>')
    assert_equal 'a  c d e', TypoHero.strip_tags('<a>a <span><script>b</script> c d</span> e</a>')
    assert_equal 'a   \(latex\) text', TypoHero.strip_tags('a <script>\(a b c\)</script><a> <test> \(latex\) text')
  end
end
