# clWiki - Version 3

clWiki is a tired, old wiki, written in the early aughts, when Ruby was still
new to the West (circa v. 1.6.8). Version 1 used `cgi` and lots of camelCased
code.
 
Version 2 was introduced in 2012 to modernize it a bit and turn it into a Rails
4 engine. It also removed support for hierarchical pages. Flat is the new cool.

Version 3 was released in 2020. It added encryptable contents and authentication
of a single user for more private contexts. It also deleted a LOT of code and
cleaned up many poor designs leftover from version 1, in addition to a lot of
other modernizations (snake_case, modern hash syntax, etc.)

## Redirect Version 1 Routes in Rails Engine

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

## Authentication and Encryption

I'm the only one using this wiki as far as I'm aware, so I've added simple user
authentication without any in-app method to create a new account. You'll need to
go to a Rails console and run `ClWiki::User.create` to make an account yourself.

Then you must set the `owner:` configuration attribute to match the user account
just created. Only a single user is supported.

Password storage uses the standard `bcrypt` / `ActiveModel::SecurePassword` 
functionality. 

If authentication is enabled, then you can optionally encrypt the contents of
any page you want. The encryption key is derived from the user's password and
uses the `lockbox` gem 

## Upgrading Pages to be Encrypted

TODO: 

## Breaking Changes in Version 3

I'm probably the only user of this wiki, so I went scorched earth to simplify
this beast. If you, gentle reader, are (a) not me and (b) using this, lemme
know. Version 2 got things working in Rails, but didn't do anything much to the
underlying code. The big stuff:

- A new in-memory index is the _only_ index supported.
- No tracking of hit counts or stats.
- No more threading with indexing. 
- Many options (probably out-of-date anyway) removed from configuration.
- All globals, except configuration, are gone.
 
