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
    $wiki_path = @test_wiki_path
    $wiki_conf = ClWiki::Configuration.new
    $wiki_conf.wiki_path = $wiki_path
    $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_NO
  end
  
  # to ward off the new Test::Unit detection of classes with no test
  # methods
  def default_test
    super unless(self.class == TestBase)
  end  
end

