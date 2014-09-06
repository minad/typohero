begin
  require 'bundler/setup'
  Bundler::GemHelper.install_tasks
rescue Exception
end

require 'rake/testtask'

Rake::TestTask.new :test do |t|
  t.libs << 'lib' << 'test'
  t.test_files = FileList['test/*.rb']
  t.verbose = true
end

task :default => :test
