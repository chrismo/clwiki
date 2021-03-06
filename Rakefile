# frozen_string_literal: true

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ClWiki'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

APP_RAKEFILE = File.expand_path('test/dummy/Rakefile', __dir__)
load 'rails/tasks/engine.rake'

Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

# Customized additions to the Rails Engine Rakefile below,
# since the current frankenstein setup has the core clWiki
# with Test::Unit tests and the new Rails Engine bits with RSpec.

RSpec::Core::RakeTask.new(:spec)

task :tests do
  errors = %w[test spec].collect do |task|
    Rake::Task[task].invoke
    nil
  rescue StandardError => e
    {task: task, exception: e}
  end.compact

  if errors.any?
    puts errors.map { |e| "Errors running #{e[:task]}! #{e[:exception].inspect}" }.join("\n")
    abort
  end
end

task :rubocop do
  sh 'bundle exec rubocop'
end

task :rubocop_metrics do
  sh 'bundle exec rubocop -c .rubocop-metrics.yml'
end

task default: :tests
task default: :rubocop
task default: :rubocop_metrics
