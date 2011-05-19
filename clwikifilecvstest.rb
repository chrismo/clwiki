# depends on commit rights to the testrep cvs repository, so these tests
# are not included in the main suite

require 'clwikifile'
require 'clwikitestbase'

class TestClWikiFileCvs < TestBase
  def setup
    super
    $wikiConf.enable_cvs = true
    $wikiConf.cvs_log = 'clwikifilecvstest.cvs.log'
  end

  def timestamp
    t = Time.now
    "#{t.year}#{t.month}#{t.day}#{t.hour}#{t.min}"  
  end
  
  def test_new_file
    f = ClWikiFile.new("/TestPage_#{timestamp}", 
      File.join(File.dirname(__FILE__), 'testrep'))
  end
  
  def test_front_page_edit
    f = ClWikiFile.new("/FrontPage", File.join(File.dirname(__FILE__), 'testrep'))
    f.content = 'content ' + timestamp
  end
end

