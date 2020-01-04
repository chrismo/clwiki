$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'cl_wiki/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'clwiki'
  s.version     = ClWiki::VERSION
  s.authors     = %w(chrismo)
  s.email       = %w(chrismo@clabs.org)
  s.homepage    = 'http://github.com/chrismo/clwiki'
  s.summary     = 'Old, tired, crappy wiki, reborn as a Rails 4+ Engine.'
  s.description = 'Old, tired, crappy wiki, reborn as a Rails 4+ Engine.'

  s.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'bcrypt', '~> 3.1'
  s.add_dependency 'clindex', '~> 2.0'
  s.add_dependency 'lockbox'

  # See Gemfile...
  # s.add_dependency "rails", git: 'git://github.com/rails/rails.git'
  # s.add_dependency "jquery-rails"
end
