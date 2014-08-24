require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.libs << "spec"
  t.test_files = FileList["spec/**/*_spec.rb"]
  t.verbose = true
end

task :default => :test
