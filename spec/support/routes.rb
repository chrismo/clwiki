# frozen_string_literal: true
# From https://github.com/radar/forem/blob/3d71dc6e0b5603789a269cfa7db36f66379eb85f/spec/support/routes.rb
#  via http://reinteractive.net/posts/2-start-your-engines
#
# This will include the routing helpers in the specs so that we can use
# forum_path, forum_topic_path and so on to get to the routes.
RSpec.configure do |c|
  c.include ClWiki::Engine.routes.url_helpers
end
