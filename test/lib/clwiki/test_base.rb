require File.dirname(__FILE__) + '/clwiki_test_helper'

require 'rubygems'
gem 'clutil'
require 'cl/util/test'
require 'configuration'

# TODO: Refactor away to module or somesuch
class TestBase < TempDirTest
  def set_temp_dir
    @temp_dir = '/tmp/clwiki'
    @test_wiki_path = @temp_dir
    $wikiPath = @test_wiki_path
    $wikiConf = ClWiki::Configuration.new
    $wikiConf.wikiPath = $wikiPath
    $wikiConf.useIndex = ClWiki::Configuration::USE_INDEX_LOCAL
  end
  
  # to ward off the new Test::Unit detection of classes with no test
  # methods
  def default_test
    super unless(self.class == TestBase)
  end  
end

