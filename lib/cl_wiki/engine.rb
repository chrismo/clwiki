# frozen_string_literal: true

# This seems a little unnecessary here, having done a bunch of zeitwerk stuff
# for auto-loading, but the formatters need to be referenced somehow in order to
# be loaded, and then registered ... but - this is working, and this ain't for
# nothing but my silly website.
require_relative '../cl_wiki_lib'

module ClWiki
  class Engine < ::Rails::Engine
    isolate_namespace ClWiki

    config.autoload_paths << "#{root}/lib"

    initializer 'cl_wiki.assets.precompile' do |app|
      app.config.assets.precompile += %w[application.css application.js]
    end
  end
end
