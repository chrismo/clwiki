ClWiki::Engine.routes.draw do
  root to: 'page#show'

  # legacy CGI
  match '/clwikicgi.rb', to: 'page#show', via: [:get], as: 'legacy'

  get '/:page_name' => 'page#show', as: 'page_show'
  get '/:page_name/edit' => 'page#edit', as: 'page_edit'
  post '/:page_name' => 'page#update'
end
