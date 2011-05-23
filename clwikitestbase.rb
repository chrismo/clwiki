require 'rubygems'
gem 'clutil'
require 'cl/util/test'
require 'clwikiconf'

class TestBase < TempDirTest
  def set_temp_dir
    @temp_dir = '/tmp/clwiki'
    @test_wiki_path = @temp_dir
    $wikiPath = @test_wiki_path
    $wikiConf = ClWikiConfiguration.new
    $wikiConf.wikiPath = $wikiPath
    $wikiConf.useIndex = ClWikiConfiguration::USE_INDEX_LOCAL
  end
  
  # to ward off the new Test::Unit detection of classes with no test
  # methods
  def default_test
    super unless(self.class == TestBase)
  end  
end

