# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/typohero'
require 'date'

Gem::Specification.new do |s|
  s.name              = 'typohero'
  s.version           = TypoHero::VERSION
  s.date              = Date.today.to_s
  s.authors           = ['Daniel Mendler']
  s.email             = ['mail@daniel-mendler.de']
  s.summary           = 'Typographic enhancer for HTML'
  s.description       = 'TypoHero improves web typography by applying various filters (similar to rubypants, typogruby, typogrify).'
  s.homepage          = 'https://github.com/minad/typohero/'
  s.license           = 'MIT'

  s.files             = `git ls-files`.split("\n")
  s.executables       = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths     = %w(lib)
end
