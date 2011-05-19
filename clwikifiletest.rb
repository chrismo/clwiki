require 'clwikifile'
require 'clwikitestbase'

class TestClWikiFile < TestBase
  # refactor: shouldn't be dealing with page paths at this level, should be at
  # the ClWikiPage level
  def doTestNewPage(fullPageName)
    fullPageName = ClWikiUtil.convertToNativePath(fullPageName)
    fileName = File.expand_path(File.join(@testWikiPath, fullPageName)) + '.txt'
    File.delete(fileName) if FileTest.exists?(fileName)
    wikiFile = ClWikiFile.new(fullPageName, @testWikiPath)
    assert(FileTest.exists?(wikiFile.fullPathAndName))
    pagePath, pageName = File.split(fullPageName)
    assert(wikiFile.name == pageName)
    assert_equal(pagePath, wikiFile.pagePath)
    assert(wikiFile.wikiRootPath == @testWikiPath)
    assert_equal(fileName, wikiFile.fullPathAndName)
    assert_equal(["Describe " + pageName + " here."], wikiFile.content)
    newWikiFile = ClWikiFile.new(fullPageName, @testWikiPath)
    assert_equal(["Describe " + pageName + " here."], newWikiFile.content)
  end

  def testNewRootPage
    doTestNewPage('/NewPage')
  end

  def testNewSubPageForwardSlash
    doTestNewPage('/NewPage/NewSubPage')
  end

  def testNewSubPageBackSlash
    doTestNewPage("\\NewPage\\NewSubPage")
  end

  def testUpdatePage
    wikiFile = ClWikiFile.new("/UpdatePage", @testWikiPath)
    assert_equal(["Describe UpdatePage here."], wikiFile.content)

    # this test looks ridiculous, but ClWikiFile actually does a write to disk
    # and re-read from the file behind the scenes here.
    # refactor rename?
    wikiFile.content = "This is new content."
    assert_equal(["This is new content."], wikiFile.content)
  end

  def testMultiUserEdit
    # this is an unlikely case, if two users set new contents almost simultaneously.
    # Not sure if this test will still be necessary, but keeping it around for now.
    wikiFileA = ClWikiFile.new("/UpdatePage", @testWikiPath)
    wikiFileB = ClWikiFile.new("/UpdatePage", @testWikiPath)
    assert_equal(["Describe UpdatePage here."], wikiFileA.content)
    assert_equal(["Describe UpdatePage here."], wikiFileB.content)

    sleep 2.5 # to ensure mtime changes. (lesser time sometimes doesn't work)
    wikiFileA.content = "This is new A content."
    begin
      wikiFileB.content = "This is new B content."
      assert(false, "Expected exception did not occur.")
    rescue ClWikiFileModifiedSinceRead
      # don do anythain, issa wha shoo 'appen
    end

    wikiFileB.readFile
    assert_equal(["This is new A content."], wikiFileB.content)
  end
end

class TestCvsUtil < TestBase
  def test_rev_inc
    assert_equal('1.1', CLabs::Util::Cvs.inc_rev('1.0', 1))
    assert_equal('1.0.0.1', CLabs::Util::Cvs.inc_rev('1.0.0.0', 1))
    assert_equal('1.1', CLabs::Util::Cvs.inc_rev('1.2', -1))
  end
end
