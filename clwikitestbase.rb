require 'cl/util/test'
require 'clwikiconf'

class TestBase < TempDirTest
  def setTempDir
    @tempDir = '/tmp/clwiki'
    @testWikiPath = @tempDir
    $wikiPath = @testWikiPath
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

