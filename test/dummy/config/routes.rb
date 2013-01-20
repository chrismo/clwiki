Rails.application.routes.draw do

  mount ClWiki::Engine => "/wiki"

  # get '/clwikicgi.rb(*all)', to: redirect("/wiki/clwikicgi.rb%{all}")
  # get '/clwikicgi.rb(*all)', to: redirect(path: '/wiki/%{all}')

  #get '/clwikicgi.rb', to: redirect(path: '/wiki/clwikicgi.rb')
  get '/clwikicgi.rb', to: redirect('/wiki/clwikicgi.rb')
end
