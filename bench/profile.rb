require 'typohero'
require 'perftools'

text = File.read('bench.txt')

PerfTools::CpuProfiler.start('/tmp/profile') do
  10.times { TypoHero.enhance(text) }
end
