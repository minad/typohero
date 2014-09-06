require 'benchmark'

require 'fast-aleck'
require 'rubypants'
require 'typogruby'
require 'typohero'

text = File.read('bench.txt')

Benchmark.bmbm do |b|
  b.report 'rubypants' do
    RubyPants.new(text).to_html
  end
  b.report 'typogruby' do
    Typogruby.improve(text)
  end
  b.report 'fast-aleck (100x)' do
    100.times { FastAleck.process(text, wrap_amps: true, wrap_caps: true, wrap_quotes: true, widont: true) }
  end
  b.report 'typohero (10x)' do
    10.times { TypoHero.enhance(text) }
  end
end
