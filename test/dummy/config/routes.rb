Rails.application.routes.draw do
  mount ClWiki::Engine => "/wiki"

  get '/clwikicgi.rb(*all)', to: redirect(path: '/wiki/clwikicgi.rb')
end
