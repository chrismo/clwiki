# clWiki

clWiki is a tired, old wiki, written when Ruby was still new to the West
(started on 1.6.8) and to my brain, and it shows. Preeeetty ugly.

The original CGI version is now in the `legacy-cgi` branch. `master`
contains the ongoing port to Rails 4 (edge) as an engine.

## No More Hierarchy

The original CGI version supported unlimited hierarchical pages, much
like a file system, but that's been discontinued in the Rails version.
You'll have to convert your wiki repository to be a single folder of
content and if you have duplicate leaf page names, you'll have to try
and reconcile the content or create unique top-level names for the
pages.

## Legacy Support in Rails Engine

Since the format of the links is changing to be rails-like, if you want
to forward old style links you'll need a redirect route in the host
Application, like so:

```
Application.routes.draw do
  mount ClWiki::Engine => "/wiki"

  get '/clwikicgi.rb', to: redirect('/wiki/clwikicgi.rb')
  get '/clwikicgi.cgi', to: redirect('/wiki/clwikicgi.rb')
end
```