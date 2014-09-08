# -*- coding: utf-8 -*-
require 'typohero/version'
require 'typohero/latex'

module TypoHero
  extend self

  EXCLUDED_TAGS = %w(head pre code kbd math script style textarea)
  EXCLUDED_TAGS_RE = /\A<(\/)?(?:#{EXCLUDED_TAGS.join('|')})[\p{Space}\/>]/im

  TOKENIZER_RE = %r{
    <!--(?:(?:(?!-->).)*)-->|            # comment
    <!\[CDATA\[(?:(?:(?!\]\]>).)*)\]\]>| # cdata
    <[^>]+>|                             # opening or closing tag
    \\[\(\)\[\]]|                        # latex begin/end
    \$\$|                                # dollar latex begin/end
    (?:(?:(?!\$\$|\\[\(\)\[\]])[^<])+)   # text without double dollar or latex
  }xm

  ESCAPE = {
    '\\\\'  => '&#92;',
    '\"'    => '&#34;',
    "\\'"   => '&#39;',
    '\.'    => '&#46;',
    '\,'    => '&#44;',
    '\-'    => '&#45;',
    '\`'    => '&#96;',
  }
  UNESCAPE = Hash[ESCAPE.map {|k,v| [v,k[1..-1]] }]
  ESCAPE_RE = Regexp.union(*ESCAPE.keys)
  UNESCAPE_RE = Regexp.union(*UNESCAPE.keys)

  NBSP  = "\u00a0"
  NBSP_THIN = "\u202F"
  MDASH = "\u2014"
  NDASH = "\u2013"
  LDQUO = "\u201C"
  RDQUO = "\u201D"
  LSQUO = "\u2018"
  RSQUO = "\u2019"
  BDQUO = "\u201E"
  ELLIPSIS = "\u2026"

  SPECIAL = {
    # enhance!
    ' - '      => " #{NDASH} ",
    '---'      => MDASH,
    '--'       => NDASH,
    '...'      => ELLIPSIS,
    '. . .'    => ELLIPSIS,
    '``'       => LDQUO,
    "''"       => RDQUO,
    '`'        => LSQUO,
    #'\''        => RSQUO, # needs more complex treatment
    ',,'       => BDQUO,
    '(c)'      => "\u00A9",
    '(C)'      => "\u00A9",
    '(r)'      => "\u00AE",
    '(R)'      => "\u00AE",
    '(tm)'     => "\u2122",
    '(TM)'     => "\u2122",
    # normalize for further processing
    '&ldquo;'  => LDQUO,
    '&rdquo;'  => RDQUO,
    '&lsquo;'  => LSQUO,
    '&rsquo;'  => RSQUO,
    '&nbsp;'   => NBSP,
    '&ndash;'  => NDASH,
    '&mdash;'  => MDASH
  }
  SPECIAL_RE = Regexp.union(*SPECIAL.keys)
  LATEX_RE = /(#{Regexp.union *LATEX.keys})(?=\p{Space}|$)/m

  DASH_RE  = "[#{MDASH}#{NDASH}]"
  AMP_RE   = '&(?:amp;)?'
  LEFT_QUOTE_RE = "[#{LDQUO}#{LSQUO}#{BDQUO}]"

  PRIME_RE = /(?<=\d)(''?)(?=[\p{Space}\dNEWS]|$)/m
  PRIMES = {
   "'"   => "\u2032",
   "''"  => "\u2033",
   "'''" => "\u2034",
  }
  ORDINAL_RE = /(?<=\d)(st|nd|rd|th)(?=\p{Space}|$)/

  MDASH_SPACE_RE = /\p{Space}*#{MDASH}\p{Space}*/
  NDASH_SPACE_RE = /\p{Space}*#{NDASH}\p{Space}*/
  MDASH_SPACE = "#{NBSP_THIN}#{MDASH}#{NBSP_THIN}"
  NDASH_SPACE = "#{NBSP}#{NDASH}#{NBSP}"

  REPLACE_AMP_RE = /(?<=\p{Space})#{AMP_RE}(?=\p{Space})/

  CAPS_BEGIN_RE  = "(^|\\p{Space}|#{LEFT_QUOTE_RE})"
  CAPS_INNER_RE  = "(?:#{AMP_RE}|[A-Z\\d\\.]|#{RSQUO})*" # right quote for posession (e.g. JIMMY'S)
  CAPS_RE        = /#{CAPS_BEGIN_RE}([A-Z\d]#{CAPS_INNER_RE}[A-Z]#{CAPS_INNER_RE}|[A-Z]#{CAPS_INNER_RE}[A-Z\d]#{CAPS_INNER_RE})/m

  RIGHT_QUOTE_RE = %r{
    ^['"](?=\p{Punct})\B|                       # Very first character is a closing quote followed by punctuation at a non-word-break
    (?<!^|#{DASH_RE}|\p{Space}|[\[\{\(\-])['"]| # Not after dash, space or opening parentheses
    ['"](?=\p{Space}|$)|                        # Followed by space or end of line
    's\b|                                       # Apostrophe
    (?<=#{DASH_RE})['"](?=\p{Punct})|           # Dash quote punctuation (e.g. --'!), for quotations
    '(?=(\d\d(?:s|\p{Space}|$)))                # Decade abbreviations (the '80s)
  }xm

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
  WIDONT_NBSP_RE = /[#{NBSP}#{NBSP_THIN}<>]/

  INITIAL_QUOTE_RE = /(?=(?:<(?:#{PARAGRAPH_RE})[^>]*>|^)(?:<(?:#{INLINE_RE})[^>]*>|\p{Space})*)#{LEFT_QUOTE_RE}/m
  INITIAL_QUOTES = {
    LSQUO => "<span class=\"quo\">#{LSQUO}</span>",
    LDQUO => "<span class=\"dquo\">#{LDQUO}</span>",
    BDQUO => "<span class=\"bdquo\">#{BDQUO}</span>",
  }

  def tokenize(input)
    comment, excluded, latex, dollar = false, 0, 0, 0
    input.scan TOKENIZER_RE do |s|
      type =
        if s =~ /\A<!--/
          :comment
        elsif s =~ /\A<!\[/
          :cdata
        end

      if !type && latex == 0 && dollar.even?
        if s=~ /\A</
          if s =~ EXCLUDED_TAGS_RE
            excluded += $1 ? -1 : 1
            excluded = 0 if excluded < 0
            type = :excluded
          else
            type = excluded == 0 ? :tag : :excluded
          end
        end
      end

      if !type && excluded == 0
        case s
        when /\A\\[\(\[]\Z/
          latex += 1
          type = :latex
        when /\A\\[\)\]]\Z/
          latex -= 1 if latex > 0
          type = :latex
        when '$$'
          dollar += 1
          type = :latex
        end
      end

      type ||=
        if excluded != 0
          :excluded
        elsif latex != 0 || dollar.odd?
          :latex
        else
          :text
        end

      yield(s, type)
    end
  end

  def tokenize_with_tags(input)
    tags = []
    tokenize(input) do |s, type|
      if type == :tag && s =~ /\A<(\/)?([^\p{Space}\/>]+)/
        if $1
          until tags.empty? || tags.pop == $2; end
        else
          tags << $2
        end
      end
      yield(s, type, tags)
    end
  end

  def truncate(input, *max_words_or_separator)
    max_words = max_words_or_separator.select {|i| Fixnum === i }.first
    if separator = max_words_or_separator.reject {|i| Fixnum === i }.first
      separator = Regexp.union(*separator) unless Regexp === separator
      separator = nil unless input =~ separator
    end
    out, tail, truncated = '', '', false
    tokenize_with_tags(input) do |s, type, tags|
      if separator && (type == :comment || type == :text || type == :latex || type == :tag) && separator === s
        out << $` if type == :text
        if type == :tag
          if s =~ /\A<\//
            tail << s
          else
            tags.pop
          end
        end
        truncated = tags
        break
      elsif max_words == 0
        if type == :text
          truncated = tags
          break
        end
        tail << s
      else
        if max_words && type == :text
          s =~ /\A(\p{Space}*)(.*)\Z/m
          ws, w = $1, $2.split(/\p{Space}+/)
          if w.size > max_words
            out << ws << w[0...max_words].join(' ')
            truncated = tags
            break
          end
          max_words -= w.size
        end
        out << s
      end
    end
    if truncated
      out.sub!(/[\p{Space}\p{Punct}]*\Z/, ELLIPSIS)
      tail << "</#{truncated.pop}>" until truncated.empty?
    end
    html_safe(input, out << tail)
  end

  def strip_tags(input)
    out = ''
    tokenize(input) {|s, type| out << s if type == :text || type == :latex }
    html_safe(input, out)
  end

  def enhance(input)
    tokens, text, prev_last_char = [], []
    tokenize(input) do |s, type|
      if type == :text
        last_char = s[-1]
        decode(s)
        escape(s)
        primes(s)
        special(s)
        latex(s)
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
      nobr(s)
      unescape(s)
    end
    html_safe(input, tokens.join)
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
          if tokens[i] =~ (state == 1 ? /(\P{Space}+)?(\p{Space}+)?(\P{Space}+\p{Space}*)\Z/m :
                                        /(\P{Space}+)?(\p{Space}+)(\P{Space}*)\Z/m)
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

  def html_safe(src, dst)
    src.respond_to?(:html_safe?) && src.html_safe? ? dst.html_safe : dst
  end

  def decode(s)
    s.gsub!(/&#x([0-9A-F]+);|&#([0-9]+);/i) do
      i = $1 ? $1.to_i(16) : $2.to_i(10)
      i == 38 ? '&amp;' : i.chr('UTF-8')
    end
  end

  def escape(s)
    s.gsub!(ESCAPE_RE, ESCAPE)
  end

  def unescape(s)
    s.gsub!(UNESCAPE_RE, UNESCAPE)
  end

  def special(s)
    s.gsub!(SPECIAL_RE, SPECIAL)
  end

  def latex(s)
    s.gsub!(LATEX_RE, LATEX)
  end

  def dash_spaces(s)
    s.gsub!(MDASH_SPACE_RE, MDASH_SPACE)
    s.gsub!(NDASH_SPACE_RE, NDASH_SPACE)
  end

  def amp(s)
    s.gsub!(REPLACE_AMP_RE, '<span class="amp">&amp;</span>')
  end

  def caps(s)
    s.gsub!(CAPS_RE, '\1<span class="caps">\2</span>')
  end

  def initial_quotes(s)
    s.gsub!(INITIAL_QUOTE_RE, INITIAL_QUOTES)
  end

  def nobr(s)
    s.gsub!(/[\p{Digit}\p{Word}]+-[\p{Digit}\p{Word}]+/, '<span class="nobr">\0</span>')
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

    # Special case for double sets of quotes, e.g.
    #   <p>He said, "'Quoted' words in a larger quote."</p>
    s.gsub!(/(?:"'|'")(?=\p{Word})/, TWO_QUOTES)
    s.gsub!(RIGHT_QUOTE_RE, RIGHT_QUOTES)
    s.gsub!(/['"]/,         LEFT_QUOTES)
  end
end
