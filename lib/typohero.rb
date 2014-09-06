module TypoHero
  VERSION = '0.0.1'

  extend self

  EXCLUDED_TAGS = %w(head pre code kbd math script textarea)
  EXCLUDED_TAGS_RE = /\A<(\/)?(?:#{EXCLUDED_TAGS.join('|')})/im

  TOKENIZER_RE = /<[^>]+>|[^<]+|\\[\(\[\)\]]|\$\$/im

  ESCAPE = {
    '\\\\'   => '&#92;',
    '\"'     => '&#34;',
    "\\\'"   => '&#39;',
    '\.'     => '&#46;',
    '\-'     => '&#45;',
    '\`'     => '&#96;'
  }
  ESCAPE_RE = Regexp.union(*ESCAPE.keys)

  EM_DASH      = '&#8212;'
  EN_DASH      = '&#8211;'
  ELLIPSIS     = '&#8230;'
  LEFT_DQUOTE  = '&#8220;'
  RIGHT_DQUOTE = '&#8221;'
  LEFT_QUOTE   = '&#8216;'
  RIGHT_QUOTE  = '&#8217;'

  SPECIAL = {
    # enhance!
    '---'      => EM_DASH,
    '--'       => EN_DASH,
    '...'      => ELLIPSIS,
    '. . .'    => ELLIPSIS,
    '``'       => LEFT_DQUOTE,
    "''"       => RIGHT_DQUOTE,
    '`'        => LEFT_QUOTE,
    ',,'       => '&#8222;',
    '-&gt;'    => '&rarr;',
    '&lt;-'    => '&larr;',
    '=&gt;'    => '&rArr;',
    '&lt;='    => '&lArr;',
    '&gt;&gt;' => '&raquo;',
    '&lt;&lt;' => '&laquo;',
    '(c)'      => '&copy;',
    '(C)'      => '&copy;',
    '(r)'      => '&reg;',
    '(R)'      => '&reg;',
    '(tm)'     => '&trade;',
    '(TM)'     => '&trade;',
    # normalize for further processing
    '&ldquo;'  => LEFT_DQUOTE,
    '&lsquo;'  => LEFT_QUOTE,
    '&rdquo;'  => RIGHT_DQUOTE,
    '&rsquo;'  => RIGHT_QUOTE,
    '&#160;'   => '&nbsp',
    '&#xA0;'   => '&nbsp',
    '&#x2013;' => EN_DASH,
    '&#x2014;' => EM_DASH,
    '&mdash;'  => EM_DASH,
    '&ndash;'  => EN_DASH,
    '&#38;'    => '&amp;',
    '&#x26;'   => '&amp;',
  }
  SPECIAL_RE = Regexp.union(*SPECIAL.keys)

  SPACE_RE = '\s|&nbsp;|&#8201;'
  DASH_RE  = '&#821[12];'
  AMP_RE   = '&(?:amp;)?'

  PRIME_RE = /(?<=\d)(''?)(?=#{SPACE_RE}|\d|$)/
  PRIMES = {
   "'" => '&prime;',
   "''" => '&Prime;',
  }
  ORDINAL_RE = /(?<=\d)(st|nd|rd|th)(?=#{SPACE_RE}|$)/

  EM_DASH_SPACE_RE = /\s*(#{EM_DASH})\s*/
  EN_DASH_SPACE_RE = /\s*(#{EN_DASH})\s*/

  REPLACE_AMP_RE  = /(?<=#{SPACE_RE})#{AMP_RE}(?=#{SPACE_RE})/m

  CAPS_BEGIN_RE   = "(^|#{SPACE_RE}|#{LEFT_DQUOTE}|#{LEFT_QUOTE})"
  CAPS_INNER_RE   = "(?:#{AMP_RE}|[A-Z\\d\\.]|#{RIGHT_QUOTE})*" # right quote for posession (e.g. JIMMY'S)
  REPLACE_CAPS_RE = /#{CAPS_BEGIN_RE}([A-Z\d]#{CAPS_INNER_RE}[A-Z]#{CAPS_INNER_RE}|[A-Z]#{CAPS_INNER_RE}[A-Z\d]#{CAPS_INNER_RE})/m

  PUNCT_CLASS = '[!"#\$\%\'()*+,\-.\/:;<=>?\@\[\\\\\]\^_`{|}~]'
  PUNCT_QUOTE_RE  = /^['"](?=#{PUNCT_CLASS})\B/m
  RIGHT_QUOTE_RE  = /(?<!^|#{DASH_RE}|#{SPACE_RE}|[\[\{\(\-])['"]|['"](?=\s|s\b|$)|(?<=#{DASH_RE})['"](?=#{PUNCT_CLASS})/m

  LEFT_QUOTES = {
    "'" => LEFT_QUOTE,
    '"' => LEFT_DQUOTE,
  }

  RIGHT_QUOTES = {
    "'" => RIGHT_QUOTE,
    '"' => RIGHT_DQUOTE,
  }

  TWO_QUOTES = {
    '"\'' => LEFT_DQUOTE + LEFT_QUOTE,
    '\'"' => LEFT_QUOTE + LEFT_DQUOTE
  }

  PARAGRAPH_RE = 'h[1-6]|p|li|dt|dd|div'
  INLINE_RE = 'a|em|span|strong|i|b'

  WIDONT_PARAGRAPH_RE = /\A<\/(?:#{PARAGRAPH_RE})>\Z/im
  WIDONT_INLINE_RE = /\A<\/?(?:#{INLINE_RE})[^>]*>\Z/im

  INITIAL_QUOTE_RE = /(?=(?:<(?:#{PARAGRAPH_RE})[^>]*>|^)(?:<(?:#{INLINE_RE})[^>]*>|\s)*)&#(8216|8220);/
  INITIAL_QUOTES = {
    LEFT_QUOTE => "<span class=\"quo\">#{LEFT_QUOTE}</span>",
    LEFT_DQUOTE => "<span class=\"dquo\">#{LEFT_DQUOTE}</span>",
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
        if tokens[i] =~ /&nbsp;|<|>/
          state = 0
        elsif state == 1 || state == 3
          if tokens[i] =~ (state == 1 ? /(\S+)?(\s+)?(\S+\s*)\Z/m : /(\S+)?(\s+)(\S*)\Z/m)
            if $1 && $2
              tokens[i].replace "#{$`}#{$1}&nbsp;#{$3}"
              state = 0
            elsif $2
              state = 2
              widow = tokens[i]
            else
              state = 3
            end
          end
        elsif state == 2 && tokens[i] =~ /(\S+\s*)\Z/m
          widow.sub!(/\A\s*/, '&nbsp;')
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
    s.gsub!(EM_DASH_SPACE_RE, '&#8201;\1&#8201;')
    s.gsub!(EN_DASH_SPACE_RE, ' \1 ')
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
      s.replace(prev_last_char =~ /\S/ ? RIGHT_QUOTES[s] : LEFT_QUOTES[s])
      return
    end

    # Special case if the very first character is a closing
    # quote followed by punctuation at a non-word-break
    s.gsub!(PUNCT_QUOTE_RE, RIGHT_QUOTES)

    # Special case for double sets of quotes, e.g.
    #   <p>He said, "'Quoted' words in a larger quote."</p>
    s.gsub!(/(?:"'|'")(?=\p{Word})/, TWO_QUOTES)

    # Special case for decade abbreviations (the '80s)
    s.gsub!(/'(?=(\d{2}(?:s|\s|$)))/, RIGHT_QUOTES)

    s.gsub!(RIGHT_QUOTE_RE, RIGHT_QUOTES)
    s.gsub!(/['"]/,         LEFT_QUOTES)
  end
end
