# frozen_string_literal: true

module ClWiki
  class Engine < ::Rails::Engine
    isolate_namespace ClWiki

    config.autoload_paths << "#{root}/lib"

    initializer 'cl_wiki.assets.precompile' do |app|
      app.config.assets.precompile += %w[application.css application.js]
    end
  end
end
