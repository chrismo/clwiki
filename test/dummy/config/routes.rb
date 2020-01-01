Rails.application.routes.draw do
  mount ClWiki::Engine => "/wiki"

  # To bypass the built-in Welcome to Rails page
  root 'cl_wiki/page#show'

  get '/clwikicgi.rb(*all)', to: redirect(path: '/wiki/clwikicgi.rb')
end
