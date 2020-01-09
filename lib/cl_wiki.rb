require 'cl_wiki/engine'

require File.expand_path('cl_wiki/configuration', __dir__)
require File.expand_path('cl_wiki/user_base', __dir__)
require File.expand_path('cl_wiki/public_user', __dir__)
require File.expand_path('cl_wiki/memory_index', __dir__)
require File.expand_path('cl_wiki/file', __dir__)
require File.expand_path('cl_wiki/page', __dir__)
require File.expand_path('cl_wiki/version', __dir__)

module ClWiki
=begin
  http://edgeguides.rubyonrails.org/engines.html#inside-an-engine

  Some engines choose to use this file to put global configuration options for their
  engine. It's a relatively good idea, and so if you want to offer configuration
  options, the file where your engine's module is defined is perfect for that. Place
  the methods inside the module and you'll be good to go.
=end
end