# frozen_string_literal: true

require_dependency 'cl_wiki/configuration'

filename = File.join(File.dirname(__FILE__), '..', '..', 'config', 'clwiki.yml')

conf_hash = YAML::load(::File.open(filename))[Rails.env]
conf_hash['wiki_path'] = ::File.expand_path(conf_hash['wiki_path'], Rails.root)
$wiki_conf = ClWiki::Configuration.new(conf_hash)
