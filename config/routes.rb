ClWiki::Engine.routes.draw do
  root to: 'page#show'

  # legacy CGI
  match '/clwikicgi.rb', to: 'page#show', via: [:get], as: 'legacy'

  # Ordering of routes matters! Anything specific, like `find` needs to be
  # _before_ the `/:page_name` route, otherwise it matches on `/:page_name`
  # before matching on the specific route.

  get '/find' => 'page#find', as: 'page_find'
  post '/find' => 'page#find'

  get '/recent' => 'page#recent', as: 'recent'

  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'

  get '/:page_name' => 'page#show', as: 'page_show'
  get '/:page_name/edit' => 'page#edit', as: 'page_edit'
  post '/:page_name' => 'page#update'
end
