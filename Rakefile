require "rake/testtask"

desc "Run all tests"
Rake::TestTask.new do |t|
  t.libs << "spec"
  t.test_files = FileList['spec/*_spec.rb','spec/geoloqi/*_spec.rb']
  t.verbose = true
end

task :default => :test
