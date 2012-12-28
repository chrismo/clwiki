require File.dirname(__FILE__) + '/clwiki_test_helper'
require 'file'
require File.dirname(__FILE__) + '/test_base'

class TestClWikiFile < TestBase
  # refactor: shouldn't be dealing with page paths at this level, should be at
  # the ClWikiPage level
  def do_test_new_page(fullPageName)
    fullPageName = ClWiki::Util.convertToNativePath(fullPageName)
    fileName = File.expand_path(File.join(@test_wiki_path, fullPageName)) + '.txt'
    File.delete(fileName) if FileTest.exists?(fileName)
    wikiFile = ClWiki::File.new(fullPageName, @test_wiki_path)
    assert(FileTest.exists?(wikiFile.fullPathAndName))
    pagePath, pageName = File.split(fullPageName)
    assert(wikiFile.name == pageName)
    assert_equal(pagePath, wikiFile.pagePath)
    assert(wikiFile.wikiRootPath == @test_wiki_path)
    assert_equal(fileName, wikiFile.fullPathAndName)
    assert_equal(["Describe " + pageName + " here."], wikiFile.content)
    newWikiFile = ClWiki::File.new(fullPageName, @test_wiki_path)
    assert_equal(["Describe " + pageName + " here."], newWikiFile.content)
  end

  def test_new_root_page
    do_test_new_page('/NewPage')
  end

  def test_new_sub_page_forward_slash
    do_test_new_page('/NewPage/NewSubPage')
  end

  def test_new_sub_page_back_slash
    do_test_new_page("\\NewPage\\NewSubPage")
  end

  def test_update_page
    wikiFile = ClWiki::File.new("/UpdatePage", @test_wiki_path)
    assert_equal(["Describe UpdatePage here."], wikiFile.content)

    # this test looks ridiculous, but ClWiki::File actually does a write to disk
    # and re-read from the file behind the scenes here.
    # refactor rename?
    wikiFile.content = "This is new content."
    assert_equal(["This is new content."], wikiFile.content)
  end

  def test_multi_user_edit
    # this can happen if 2 people load a page, then both edit the page - the last one
    # to submit would stomp the first edit ... unless:
    wiki_file_a = ClWiki::File.new("/UpdatePage", @test_wiki_path)
    wiki_file_b = ClWiki::File.new("/UpdatePage", @test_wiki_path)
    assert_equal(["Describe UpdatePage here."], wiki_file_a.content)
    assert_equal(["Describe UpdatePage here."], wiki_file_b.content)

    sleep 2.5 # to ensure mtime changes. (lesser time sometimes doesn't work)
    wiki_file_a.content = "This is new A content."
    begin
      wiki_file_b.content = "This is new B content."
      assert(false, "Expected exception did not occur.")
    rescue ClWiki::FileModifiedSinceRead
      # don do anythain, issa wha shoo 'appen
    end

    wiki_file_b.readFile
    assert_equal(["This is new A content."], wiki_file_b.content)
  end

  def test_multi_user_edit_dst
    # running into a problem where I can't edit a page that was last edited outside
    # of DST when I'm in DST ... it raises ClWiki::FileModifiedSinceRead
    wiki_file = ClWiki::File.new("/UpdateDstPage", @test_wiki_path)
    assert_equal(["Describe UpdateDstPage here."], wiki_file.content)
    File.utime(Time.now, Time.local(2011, "jan", 1), wiki_file.fullPathAndName)

    wiki_file_read = ClWiki::File.new("/UpdateDstPage", @test_wiki_path)
    wiki_file_read.content = "This is new A content."
    assert_equal(["This is new A content."], wiki_file_read.content)
  end
end

class TestCvsUtil < TestBase
  def test_rev_inc
    assert_equal('1.1', CLabs::Util::Cvs.inc_rev('1.0', 1))
    assert_equal('1.0.0.1', CLabs::Util::Cvs.inc_rev('1.0.0.0', 1))
    assert_equal('1.1', CLabs::Util::Cvs.inc_rev('1.2', -1))
  end
end