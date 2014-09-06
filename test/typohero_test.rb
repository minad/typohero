require 'minitest/autorun'
require 'typohero'

class TypoheroTest < Minitest::Test
  def typo(str, orig)
    # todo test recursive
    a = TypoHero.enhance(str)
    #b = TypoHero.enhance(a)
    #assert_equal a, b
    #c = Typogruby.improve(str)
    #puts "\nInput:     #{str}\nTypogruby: #{c}\nTypoHero:      #{a}\n" if a != c
    assert_equal orig, a
  end

  def test_verbatim
    typo "foo!", "foo!"
    typo "<div>This is html</div>", "<div>This is&nbsp;html</div>"
    typo "<div>This is html with <crap </div> tags>", "<div>This is html with <crap </div> tags>"
    typo %q{
multiline

<b>html</b>

code

}, %q{
multiline

<b>html</b>&nbsp;code

}
  end

  def test_quotes
    typo '"A first example"', '<span class="dquo">&#8220;</span>A first&nbsp;example&#8221;'
    typo '"A first "nested" example"',
                    '<span class="dquo">&#8220;</span>A first &#8220;nested&#8221;&nbsp;example&#8221;'

    typo '".', '&#8221;.'
    typo '"a', '<span class="dquo">&#8220;</span>a'

    typo "'.", '&#8217;.'
    typo "'a", '<span class="quo">&#8216;</span>a'

    typo %{<p>He said, "'Quoted' words in a larger quote."</p>},
    '<p>He said, &#8220;&#8216;Quoted&#8217; words in a larger&nbsp;quote.&#8221;</p>'

    typo %{"I like the 70's"}, '<span class="dquo">&#8220;</span>I like the&nbsp;70&#8217;s&#8221;'
    typo %{"I like the '70s"}, '<span class="dquo">&#8220;</span>I like the&nbsp;&#8217;70s&#8221;'
    typo %{"I like the '70!"}, '<span class="dquo">&#8220;</span>I like the&nbsp;&#8216;70!&#8221;'

    typo 'pre"post', 'pre&#8221;post'
    typo 'pre "post', 'pre&nbsp;&#8220;post'
    typo 'pre&nbsp;"post', 'pre&nbsp;&#8220;post'
    typo 'pre--"post', 'pre &#8211;&nbsp;&#8220;post'
    typo 'pre--"!', 'pre &#8211;&nbsp;&#8221;!'

    typo "pre'post", 'pre&#8217;post'
    typo "pre 'post", 'pre&nbsp;&#8216;post'
    typo "pre&nbsp;'post", 'pre&nbsp;&#8216;post'
    typo "pre--'post", 'pre &#8211;&nbsp;&#8216;post'
    typo "pre--'!", 'pre &#8211;&nbsp;&#8217;!'

    typo "<b>'</b>", '<b><span class="quo">&#8216;</span></b>'
    typo "foo<b>'</b>", "foo<b>&#8217;</b>"

    typo '<b>"</b>', '<b><span class="dquo">&#8220;</span></b>'
    typo 'foo<b>"</b>', "foo<b>&#8221;</b>"
  end

  def test_dashes
    typo "foo--bar", 'foo &#8211;&nbsp;bar'
    typo "foo---bar", 'foo&#8201;&#8212;&#8201;bar'
  end

  def test_ellipses
    typo "foo..bar", 'foo..bar'
    typo "foo...bar", 'foo&#8230;bar'
    typo "foo....bar", 'foo&#8230;.bar'

    typo "foo. . ..bar", 'foo&#8230;.bar'
    typo "foo. . ...bar", 'foo&#8230;..bar'
    typo "foo. . ....bar", 'foo&#8230;&#8230;bar'
  end

  def test_backticks
    typo "pre``post", 'pre&#8220;post'
    typo "pre ``post", 'pre&nbsp;&#8220;post'
    typo "pre&nbsp;``post", 'pre&nbsp;&#8220;post'
    typo "pre--``post", 'pre &#8211;&nbsp;&#8220;post'
    typo "pre--``!", 'pre &#8211;&nbsp;&#8220;!'

    typo "pre''post", 'pre&#8221;post'
    typo "pre ''post", 'pre&nbsp;&#8221;post'
    typo "pre&nbsp;''post", 'pre&nbsp;&#8221;post'
    typo "pre--''post", 'pre &#8211;&nbsp;&#8221;post'
    typo "pre--''!", 'pre &#8211;&nbsp;&#8221;!'
  end

  def test_single_backticks
    typo "`foo'", '<span class="quo">&#8216;</span>foo&#8217;'

    typo "pre`post", 'pre&#8216;post'
    typo "pre `post", 'pre&nbsp;&#8216;post'
    typo "pre&nbsp;`post", 'pre&nbsp;&#8216;post'
    typo "pre--`post", 'pre &#8211;&nbsp;&#8216;post'
    typo "pre--`!", 'pre &#8211;&nbsp;&#8216;!'

    typo "pre'post", 'pre&#8217;post'
    typo "pre 'post", 'pre&nbsp;&#8216;post'
    typo "pre&nbsp;'post", 'pre&nbsp;&#8216;post'
    typo "pre--'post", 'pre &#8211;&nbsp;&#8216;post'
    typo "pre--'!", 'pre &#8211;&nbsp;&#8217;!'
  end

  def test_process_escapes
    typo %q{foo\bar}, "foo\\bar"
    typo %q{foo\\\bar}, "foo&#92;bar"
    typo %q{foo\\\\\bar}, "foo&#92;\\bar"
    typo %q{foo\...bar}, "foo&#46;..bar"
    typo %q{foo\.\.\.bar}, "foo&#46;&#46;&#46;bar"

    typo %q{foo\'bar}, "foo&#39;bar"
    typo %q{foo\"bar}, "foo&#34;bar"
    typo %q{foo\-bar}, "foo&#45;bar"
    typo %q{foo\`bar}, "foo&#96;bar"

    typo %q{foo\#bar}, "foo\\#bar"
    typo %q{foo\*bar}, "foo\\*bar"
    typo %q{foo\&bar}, "foo\\&bar"
  end

  def test_should_replace_amps
    typo 'One & two', 'One <span class="amp">&amp;</span>&nbsp;two'
    typo 'One &amp; two', 'One <span class="amp">&amp;</span>&nbsp;two'
    typo 'One &#38; two', 'One <span class="amp">&amp;</span>&nbsp;two'
    typo 'One&nbsp;&amp;&nbsp;two', 'One&nbsp;<span class="amp">&amp;</span>&nbsp;two'
  end

  def test_should_ignore_special_amps
    typo 'One <span class="amp">&amp;</span> two', 'One <span class="amp">&amp;</span>&nbsp;two'
    typo '&ldquo;this&rdquo; & <a href="/?that&amp;test">that</a>', '<span class="dquo">&#8220;</span>this&#8221; <span class="amp">&amp;</span>&nbsp;<a href="/?that&amp;test">that</a>'
  end

  def test_should_replace_caps
    typo "A message from KU", 'A message from&nbsp;<span class="caps">KU</span>'
    typo 'Replace text <a href=".">IN</a> tags', 'Replace text <a href="."><span class="caps">IN</span></a>&nbsp;tags'
    typo 'Replace text <i>IN</i> tags', 'Replace text <i><span class="caps">IN</span></i>&nbsp;tags'
  end

  def test_should_ignore_special_case_caps
    typo 'It should ignore just numbers like 1234.', 'It should ignore just numbers like&nbsp;1234.'
    typo "<pre>CAPS</pre> more CAPS", '<pre>CAPS</pre> more&nbsp;<span class="caps">CAPS</span>'
    typo "<Pre>CAPS</PRE> with odd tag names CAPS", '<Pre>CAPS</PRE> with odd tag names&nbsp;<span class="caps">CAPS</span>'
    typo "A message from 2KU2 with digits", 'A message from <span class="caps">2KU2</span> with&nbsp;digits'
    typo "Dotted caps followed by spaces should never include them in the wrap D.O.T.   like so.", 'Dotted caps followed by spaces should never include them in the wrap <span class="caps">D.O.T.</span>   like&nbsp;so.'
    typo 'Caps in attributes (<span title="Example CAPS">example</span>) should be ignored', 'Caps in attributes (<span title="Example CAPS">example</span>) should be&nbsp;ignored'
    typo '<head><title>CAPS Example</title></head>', '<head><title>CAPS Example</title></head>'
  end

  def test_should_not_break_caps_with_apostrophes
    typo "JIMMY'S", '<span class="caps">JIMMY&#8217;S</span>'
    typo "<i>D.O.T.</i>HE34T<b>RFID</b>", '<i><span class="caps">D.O.T.</span></i><span class="caps">HE34T</span><b><span class="caps">RFID</span></b>'
  end

  def test_should_not_break_caps_with_ampersands
    typo "AT&T", '<span class="caps">AT&T</span>'
    typo "AT&amp;T", '<span class="caps">AT&amp;T</span>'
    typo "AT&#38;T", '<span class="caps">AT&amp;T</span>'
  end

  def test_should_prevent_widows
    typo 'A very simple test', 'A very simple&nbsp;test'
  end

  def test_should_not_change_single_word_items
    typo 'Test', 'Test'
    typo ' Test', ' Test'
    typo '<ul><li>Test</p></li><ul>', '<ul><li>Test</p></li><ul>'
    typo '<ul><li> Test</p></li><ul>', '<ul><li> Test</p></li><ul>'
    typo '<p>In a couple of paragraphs</p><p>paragraph two</p>', '<p>In a couple of&nbsp;paragraphs</p><p>paragraph&nbsp;two</p>'
    typo '<h1><a href="#">In a link inside a heading</i> </a></h1>', '<h1><a href="#">In a link inside a&nbsp;heading</i> </a></h1>'
    typo '<h1><a href="#">In a link</a> followed by other text</h1>', '<h1><a href="#">In a link</a> followed by other&nbsp;text</h1>'
  end

  def test_should_not_add_nbsp_before_another
    typo 'Sentence with one&nbsp;nbsp', 'Sentence with one&nbsp;nbsp'
  end

  def test_should_not_error_on_empty_html
    typo '<h1><a href="#"></a></h1>', '<h1><a href="#"></a></h1>'
  end

  def test_should_ignore_widows_in_special_tags
    typo '<div>Divs get love!</div>', '<div>Divs get&nbsp;love!</div>'
    typo '<pre>Neither do PREs</pre>', '<pre>Neither do PREs</pre>'
    typo '<textarea>nor text in textarea</textarea>', '<textarea>nor text in textarea</textarea>'
    typo "<script>\nreturn window;\n</script>", "<script>\nreturn window;\n</script>"
    typo '<div><p>But divs with paragraphs do!</p></div>', '<div><p>But divs with paragraphs&nbsp;do!</p></div>'
  end

  def test_widont
    code = %q{
<ul>
  <li>
    <a href="/contact/">Contact</a>
  </li>
</ul>}
    typo code, code
  end

  def test_should_replace_quotes
    typo '"With primes"', '<span class="dquo">&#8220;</span>With&nbsp;primes&#8221;'
    typo "'With single primes'", '<span class="quo">&#8216;</span>With single&nbsp;primes&#8217;'
    typo '<a href="#">"With primes and a link"</a>', '<a href="#"><span class="dquo">&#8220;</span>With primes and a&nbsp;link&#8221;</a>'
    typo '&#8220;With smartypanted quotes&#8221;', '<span class="dquo">&#8220;</span>With smartypanted&nbsp;quotes&#8221;'
    typo '&lsquo;With manual quotes&rsquo;', '<span class="quo">&#8216;</span>With manual&nbsp;quotes&#8217;'
  end

  def test_should_apply_all_filters
    typo '<h2>"Jayhawks" & KU fans act extremely obnoxiously</h2>', '<h2><span class="dquo">&#8220;</span>Jayhawks&#8221; <span class="amp">&amp;</span> <span class="caps">KU</span> fans act extremely&nbsp;obnoxiously</h2>'
  end

  def test_other_special
    typo ',,hello\'\'', '&#8222;hello&#8221;'
    typo '&lt;&lt;', '&laquo;'
    typo '&gt;&gt;', '&raquo;'
    typo '-&gt;', '&rarr;'
    typo '&lt;-', '&larr;'
    typo '(tm)', '&trade;'
  end

  def test_primes
    typo "She's  6'2''", 'She&#8217;s&nbsp;6&prime;2&Prime;'
  end

  def test_ordinals
    typo 'I am the 1st', 'I am the&nbsp;1<sup>st</sup>'
  end
end
