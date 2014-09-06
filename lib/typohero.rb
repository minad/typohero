module TypoHero
  VERSION = '0.0.1'

  extend self

  EXCLUDED_TAGS = %w(head pre code kbd math script textarea)
  EXCLUDED_TAGS_RE = /\A<(\/)?(?:#{EXCLUDED_TAGS.join('|')})[\p{Space}\/>]/im

  TOKENIZER_RE = /<[^>]+>|[^<]+|\\[\(\[\)\]]|\$\$/im

  ESCAPE = {
    '\\\\'   => '&#92;',
    '\"'     => '&#34;',
    "\\\'"   => '&#39;',
    '\.'     => '&#46;',
    '\,'     => '&#44;',
    '\-'     => '&#45;',
    '\`'     => '&#96;',
    '\('     => '&#40',
  }
  ESCAPE_RE = Regexp.union(*ESCAPE.keys)

  NBSP  = "\u00a0"
  MDASH = "\u2014"
  NDASH = "\u2013"
  LDQUO = "\u201C"
  RDQUO = "\u201D"
  LSQUO = "\u2018"
  RSQUO = "\u2019"
  BDQUO = "\u201E"

  SPECIAL = {
    # enhance!
    '---'      => MDASH,
    '--'       => NDASH,
    '...'      => "\u2026",
    '. . .'    => "\u2026",
    '``'       => LDQUO,
    "''"       => RDQUO,
    '`'        => LSQUO,
    ',,'       => BDQUO,
    '-&gt;'    => "\u2192",
    '&lt;-'    => "\u2190",
    '=&gt;'    => "\u21D2",
    '&lt;='    => "\u21D0",
    '&gt;&gt;' => "\u00BB",
    '&lt;&lt;' => "\u00AB",
    '(c)'      => "\u00A9",
    '(C)'      => "\u00A9",
    '(r)'      => "\u00AE",
    '(R)'      => "\u00AE",
    '(tm)'     => "\u2122",
    '(TM)'     => "\u2122",
    # normalize for further processing
    '&ldquo;'  => LDQUO,
    '&#8220;'  => LDQUO,
    '&#x201C;' => LDQUO,
    '&rdquo;'  => RDQUO,
    '&#8221;'  => RDQUO,
    '&#x201D;' => RDQUO,
    '&lsquo;'  => LSQUO,
    '&#8216;'  => LSQUO,
    '&#x2018;' => LSQUO,
    '&rsquo;'  => RSQUO,
    '&#8217;'  => RSQUO,
    '&#x2019;' => RSQUO,
    '&#160;'   => NBSP,
    '&#xA0;'   => NBSP,
    '&nbsp;'   => NBSP,
    '&ndash;'  => NDASH,
    '&#x2013;' => NDASH,
    '&#8211;'  => NDASH,
    '&#x2014;' => MDASH,
    '&mdash;'  => MDASH,
    '&#8212;'  => MDASH,
    '&#38;'    => '&amp;',
    '&#x26;'   => '&amp;',
  }
  SPECIAL_RE = Regexp.union(*SPECIAL.keys)

  DASH_RE  = "[#{MDASH}#{NDASH}]"
  AMP_RE   = '&(?:amp;)?'
  LEFT_QUOTE_RE = "[#{LDQUO}#{LSQUO}#{BDQUO}]"

  PRIME_RE = /(?<=\d)(''?)(?=\p{Space}|\d|$)/
  PRIMES = {
   "'"   => "\u2032",
   "''"  => "\u2033",
   "'''" => "\u2034",
  }
  ORDINAL_RE = /(?<=\d)(st|nd|rd|th)(?=\p{Space}|$)/

  MDASH_SPACE_RE = /\p{Space}*(#{MDASH})\p{Space}*/
  NDASH_SPACE_RE = /\p{Space}*(#{NDASH})\p{Space}*/

  REPLACE_AMP_RE  = /(?<=\p{Space})#{AMP_RE}(?=\p{Space})/m

  CAPS_BEGIN_RE   = "(^|\\p{Space}|#{LEFT_QUOTE_RE})"
  CAPS_INNER_RE   = "(?:#{AMP_RE}|[A-Z\\d\\.]|#{RSQUO})*" # right quote for posession (e.g. JIMMY'S)
  REPLACE_CAPS_RE = /#{CAPS_BEGIN_RE}([A-Z\d]#{CAPS_INNER_RE}[A-Z]#{CAPS_INNER_RE}|[A-Z]#{CAPS_INNER_RE}[A-Z\d]#{CAPS_INNER_RE})/m

  PUNCT_CLASS = '[!"#\$\%\'()*+,\-.\/:;<=>?\@\[\\\\\]\^_`{|}~]'
  PUNCT_QUOTE_RE  = /^['"](?=#{PUNCT_CLASS})\B/m
  RIGHT_QUOTE_RE  = /(?<!^|#{DASH_RE}|\p{Space}|[\[\{\(\-])['"]|['"](?=\p{Space}|s\b|$)|(?<=#{DASH_RE})['"](?=#{PUNCT_CLASS})/m

  LEFT_QUOTES = {
    "'" => LSQUO,
    '"' => LDQUO,
  }

  RIGHT_QUOTES = {
    "'" => RSQUO,
    '"' => RDQUO,
  }

  TWO_QUOTES = {
    '"\'' => LDQUO + LSQUO,
    '\'"' => LSQUO + LDQUO
  }

  PARAGRAPH_RE = 'h[1-6]|p|li|dt|dd|div'
  INLINE_RE = 'a|em|span|strong|i|b'

  WIDONT_PARAGRAPH_RE = /\A<\/(?:#{PARAGRAPH_RE})>\Z/im
  WIDONT_INLINE_RE = /\A<\/?(?:#{INLINE_RE})[^>]*>\Z/im
  WIDONT_NBSP_RE = /#{NBSP}|<|>/

  INITIAL_QUOTE_RE = /(?=(?:<(?:#{PARAGRAPH_RE})[^>]*>|^)(?:<(?:#{INLINE_RE})[^>]*>|\p{Space})*)#{LEFT_QUOTE_RE}/
  INITIAL_QUOTES = {
    LSQUO => "<span class=\"quo\">#{LSQUO}</span>",
    LDQUO => "<span class=\"dquo\">#{LDQUO}</span>",
    BDQUO => "<span class=\"bdquo\">#{BDQUO}</span>",
  }

  def tokenize(input)
    excluded, latex, dollar = 0, 0, 0
    input.scan TOKENIZER_RE do |s|
      text = false
      case s
      when /\A</
        excluded += ($1 ? -1 : 1) if s =~ EXCLUDED_TAGS_RE
      when /\A\\[\(\[]\Z/
        latex += 1
      when /\A\\[\)\]]\Z/
        latex -= 1
      when '$$'
        dollar += 1
      else
        text = true if latex == 0 && dollar.even? && excluded == 0
      end
      yield(s, text)
    end
  end

  def enhance(input)
    tokens, text, prev_last_char = [], []
    tokenize(input) do |s, t|
      if t
        last_char = s[-1]
        escape(s)
        primes(s)
        special(s)
        quotes(s, prev_last_char)
        dash_spaces(s)
        prev_last_char = last_char
        text << s
      end
      tokens << s
    end
    widont(tokens)
    text.each do |s|
      initial_quotes(s)
      amp(s)
      caps(s)
      ordinals(s)
    end
    tokens.join
  end

  def widont(tokens)
    state, i, widow = 1, tokens.size - 1, nil
    while i >= 0
      if tokens[i] =~ WIDONT_PARAGRAPH_RE
        state = 1
      elsif tokens[i] !~ WIDONT_INLINE_RE
        if tokens[i] =~ WIDONT_NBSP_RE
          state = 0
        elsif state == 1 || state == 3
          if tokens[i] =~ (state == 1 ? /(\P{Space}+)?(\p{Space}+)?(\P{Space}+\p{Space}*)\Z/m : /(\P{Space}+)?(\p{Space}+)(\P{Space}*)\Z/m)
            if $1 && $2
              tokens[i].replace "#{$`}#{$1}#{NBSP}#{$3}"
              state = 0
            elsif $2
              state = 2
              widow = tokens[i]
            else
              state = 3
            end
          end
        elsif state == 2 && tokens[i] =~ /(\P{Space}+\p{Space}*)\Z/m
          widow.sub!(/\A\p{Space}*/, NBSP)
          state = 0
        end
      end
      i -= 1
    end
  end

  def escape(s)
    s.gsub!(ESCAPE_RE, ESCAPE)
  end

  def special(s)
    s.gsub!(SPECIAL_RE, SPECIAL)
  end

  def dash_spaces(s)
    s.gsub!(MDASH_SPACE_RE, "\u2009\\1\u2009")
    s.gsub!(NDASH_SPACE_RE, ' \1 ')
  end

  def amp(s)
    s.gsub!(REPLACE_AMP_RE, '<span class="amp">&amp;</span>')
  end

  def caps(s)
    s.gsub!(REPLACE_CAPS_RE, '\1<span class="caps">\2</span>')
  end

  def initial_quotes(s)
    s.gsub!(INITIAL_QUOTE_RE, INITIAL_QUOTES)
  end

  def primes(s)
    # Special case for inches and minutes, seconds
    s.gsub!(PRIME_RE, PRIMES)
  end

  def ordinals(s)
    s.gsub!(ORDINAL_RE, '<sup>\1</sup>')
  end

  def quotes(s, prev_last_char)
    if s =~ /\A['"]\Z/
      s.replace(prev_last_char =~ /\P{Space}/ ? RIGHT_QUOTES[s] : LEFT_QUOTES[s])
      return
    end

    # Special case if the very first character is a closing
    # quote followed by punctuation at a non-word-break
    s.gsub!(PUNCT_QUOTE_RE, RIGHT_QUOTES)

    # Special case for double sets of quotes, e.g.
    #   <p>He said, "'Quoted' words in a larger quote."</p>
    s.gsub!(/(?:"'|'")(?=\p{Word})/, TWO_QUOTES)

    # Special case for decade abbreviations (the '80s)
    s.gsub!(/'(?=(\d{2}(?:s|\p{Space}|$)))/, RIGHT_QUOTES)

    s.gsub!(RIGHT_QUOTE_RE, RIGHT_QUOTES)
    s.gsub!(/['"]/,         LEFT_QUOTES)
  end
end
