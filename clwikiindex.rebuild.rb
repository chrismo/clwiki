require 'drb'
require 'clwikiconf'

ClWikiConfiguration.load_xml
DRb.start_service
server = DRbObject.new(nil, "druby://localhost:#{$wikiConf.indexPort}")
server.build
server.save
