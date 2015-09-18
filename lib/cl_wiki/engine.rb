module ClWiki
  class Engine < ::Rails::Engine
    isolate_namespace ClWiki

    initializer 'cl_wiki.assets.precompile' do |app|
      app.config.assets.precompile += %w(application.css application.js)
    end
  end
end
