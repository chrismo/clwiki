require File.dirname(__FILE__) + '/clwiki_test_helper'
require 'page'

# stub this out for testing
class ClWiki::Page
  @@page_exists = false
  @@page_globally_exists = false

  def self.set_page_exists(value)
    @@page_exists = value
  end

  def self.page_exists?(pageFullName)
    @@page_exists
  end
end

class TestClWikiPage < TestBase
  def test_wiki_page
    newPage = ClWiki::Page.new('/NewPage')
  end

  def do_test_convert_to_link(pageName, pagePath='/FrontPage')
    f = ClWiki::PageFormatter.new(nil, pagePath)
    fullPageName = f.expand_path(pageName, pagePath)
    ClWiki::Page.set_page_exists(false)
    $wikiConf.editable = true
    assert_equal(
      pageName + "<a href=clwikicgi.rb?page=" + fullPageName + "&edit=true>?</a>",
      f.convertToLink(pageName))
    $wikiConf.editable = false
    assert_equal(
      pageName,
      f.convertToLink(pageName))
    ClWiki::Page.set_page_exists(true)

    # now that links serve up a separate link for each page in the
    # hierarchy, testing this is cumbersome - and there's already
    # tests for testFormatLinkPages which exercise this same thing

    # assert_equal(
    #  "<a href=clwikicgi.rb?page=" + fullPageName + ">" + pageName + "</a>",
    #   f.convertToLink(pageName))
  end

  def test_convert_to_link_main
    do_test_convert_to_link("TestPage")
  end

  def test_convert_to_link_sub_bs
    do_test_convert_to_link("TestPage\TestSubPage")
  end

  def test_convert_to_link_sub_fs
    do_test_convert_to_link("TestPage/TestSubPage")
  end

  def test_convert_to_link_bs_sub
    do_test_convert_to_link("\TestPage/TestSubPage")
  end

  def test_convert_to_link_fs_sub
    do_test_convert_to_link("/TestPage/TestSubPage")
  end

  def test_convert_to_link_fs_sub_sub
    do_test_convert_to_link("/TestPage/TestSubPage\NotherSubPage")
  end

  def test_convert_to_link_fs_sub_sub2
    do_test_convert_to_link("/TestPage/TestSubPage/NotherSubPage")
  end

  def test_convert_to_link_collapse_path
    do_test_convert_to_link("TestSubPage/NotherSubPage", "/TestPage/TestSubPage")
    do_test_convert_to_link("SubPage/NotherSubPage", "/TestPage/SubPage/SubPage")
  end

  def test_page_expand_path
    f = ClWiki::PageFormatter.new
    # This group never happens, because there's always a root page, not just a root dir
    # assert_equal("/a",               f.expand_path("a", "/"))
    # assert_equal("/a",               f.expand_path("//a", "/"))
    # assert_equal("/a",               f.expand_path("/a", "/"))

    assert_equal("/b",               f.expand_path("b", "/a"))
    assert_equal("/b",               f.expand_path("//b", "/a"))
    assert_equal("/a/b",             f.expand_path("/b", "/a"))

    assert_equal("/a/c",             f.expand_path("c", "/a/b"))
    assert_equal("/c",               f.expand_path("//c", "/a/b"))
    assert_equal("/a/b/c",           f.expand_path("/c", "/a/b"))

    assert_equal("/a/b/d",           f.expand_path("d", "/a/b/c"))
    assert_equal("/d",               f.expand_path("//d", "/a/b/c"))
    assert_equal("/a/b/c/d",         f.expand_path("/d", "/a/b/c"))

    assert_equal("/a/b/c",           f.expand_path("b/c", "/a/b/c/d/e"))
    assert_equal("/b/c",             f.expand_path("//b/c", "/a/b/c/d/e"))
    assert_equal("/a/b",             f.expand_path("b", "/a/b/c/d/e"))
    assert_equal("/a/b/c/f",         f.expand_path("b/c/f", "/a/b/c/d/e"))
    assert_equal("/a/b/c/d/m/n/o",   f.expand_path("m/n/o", "/a/b/c/d/e"))
    assert_equal("/a/b/c/a/b/d",     f.expand_path("a/b/d", "/a/b/c/a/b/c"))
    assert_equal("/a/b",             f.expand_path("/a/b", "/"))
    assert_equal("/m/n",             f.expand_path("//m/n", "/a/b"))
  end

  def test_gsub_words
    original =
      'test page PageName ' +
      'PageName/SubPage PageName\SubPage\SubPage ' +
      '/PageName/SubPage \PageName\SubPage\SubPage ' +
      'test.thing test, <tagger> </tagger> oops>whoops ' +
      'oops<thing>bleh hen<butter '
    expectedResults =
      ['test', 'page', 'PageName',
       'PageName/SubPage', 'PageName\SubPage\SubPage',
       '/PageName/SubPage', '\PageName\SubPage\SubPage',
       'test', 'thing', 'test', '<tagger>', '</tagger>', 'oops', 'whoops',
       'oops', '<thing>', 'bleh', 'hen', 'butter']

    actualResults = Array.new
    f = ClWiki::PageFormatter.new(original)
    f.gsubWords { |word| actualResults << word }
    assert_equal(expectedResults, actualResults)
  end

  def do_test_format_links(content, expectedContent, currentPagePath='/FrontPage', pageExists=true, pageGloballyExists=false)
    if pageGloballyExists
      globalFullPageName = '/GlobalRoot/' + content
    else
      globalFullPageName = nil
    end

    $wikiConf.editable = true
    f = ClWiki::PageFormatter.new(content, currentPagePath)
    ClWiki::Page.set_page_exists(pageExists)
    assert_equal(expectedContent, f.formatLinks, "content: #{content} pageExists: #{pageExists} pageGloballyExists: #{pageGloballyExists} editable")

    $wikiConf.editable = false
    f = ClWiki::PageFormatter.new(content, currentPagePath)
    ClWiki::Page.set_page_exists(pageExists)
    if !pageExists
      assert_equal(content, f.formatLinks, "content: #{content} pageExists: #{pageExists} pageGloballyExists: #{pageGloballyExists} not editable")
    else
      assert_equal(expectedContent, f.formatLinks, "content: #{content} pageExists: #{pageExists} pageGloballyExists: #{pageGloballyExists} not editable")
    end
  end

  def test_format_link_pages
    do_test_format_links('TestPage', "TestPage<a href=clwikicgi.rb?page=/TestPage&edit=true>?</a>", '/FrontPage', false)
    do_test_format_links('TestPage', "<a href=clwikicgi.rb?page=/TestPage>TestPage</a>", '/FrontPage', true)

    # this is an important test. The scanning includes some punctuation
    # as word characters, but not others. Comma ain't one of them, so this
    # makes sure the division of characters is working right.
    do_test_format_links('TestPage,', "<a href=clwikicgi.rb?page=/TestPage>TestPage</a>,", '/FrontPage', true)

    # the current parsing skips over the brackets, so the tags
    # are returned intact. IE 5 just ignores them.
    # In the future I need to code no wiki links within
    # brackets which means parsing them.
    do_test_format_links('<NoWikiLinks>TestPage</NoWikiLinks>', "TestPage")

    # No WikiLinks within < >, to avoid problems with href
    do_test_format_links('<a href="www.NotAWikiPage.com">some link</a>', '<a href="www.NotAWikiPage.com">some link</a>')

    do_test_format_links('/TestPage',
                      "/<a href=clwikicgi.rb?page=/FrontPage/TestPage>TestPage</a>",
                      '/FrontPage', true)
    do_test_format_links('TestPage/TestSubPage',
                      "<a href=clwikicgi.rb?page=/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/TestPage/TestSubPage>TestSubPage</a>",
                      '/FrontPage', true)
    do_test_format_links('TestPage/TestSubPage',
                      "<a href=clwikicgi.rb?page=/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/TestPage/TestSubPage>TestSubPage</a>",
                      '/SubRoot', true)
    do_test_format_links('/TestPage/TestSubPage',
                      "/<a href=clwikicgi.rb?page=/SubRoot/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/SubRoot/TestPage/TestSubPage>TestSubPage</a>",
                      '/SubRoot', true)
    do_test_format_links('//TestPage/TestSubPage',
                      "//<a href=clwikicgi.rb?page=/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/TestPage/TestSubPage>TestSubPage</a>",
                      '/SubRoot', true)
    do_test_format_links('TestPage/TestSubPage',
                      "<a href=clwikicgi.rb?page=/SubRootA/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/SubRootA/TestPage/TestSubPage>TestSubPage</a>",
                      '/SubRootA/SubRootB', true)
    do_test_format_links('/TestPage/TestSubPage',
                      "/<a href=clwikicgi.rb?page=/SubRootA/SubRootB/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/SubRootA/SubRootB/TestPage/TestSubPage>TestSubPage</a>",
                      '/SubRootA/SubRootB', true)
    do_test_format_links('//TestPage/TestSubPage',
                      "//<a href=clwikicgi.rb?page=/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/TestPage/TestSubPage>TestSubPage</a>",
                      '/SubRootA/SubRootB', true)
    do_test_format_links('TestPage\TestSubPage',
                      "<a href=clwikicgi.rb?page=/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/TestPage/TestSubPage>TestSubPage</a>",
                      '/FrontPage', true)
    do_test_format_links('TestPage',
                      "<a href=clwikicgi.rb?page=/SubRootA/SubRootB/TestPage>TestPage</a>",
                      '/SubRootA/SubRootB/TestPage', true)
    do_test_format_links('TestPage',
                      "TestPage<a href=clwikicgi.rb?page=/SubRootA/SubRootB/TestPage&edit=true>?</a>",
                      '/SubRootA/SubRootB/MasterTestPage', false)
  end

  def test_is_wiki_name
    f = ClWiki::PageFormatter.new
    assert(f.isWikiName?("WikiName"))
    assert(!f.isWikiName?("WikiName,"))
    assert(!f.isWikiName?("Wikiname"))
    assert(!f.isWikiName?("wIkiName"))
    assert(!f.isWikiName?("<h1>wikiName</h1><br>Other"))
    assert(!f.isWikiName?("<WikiName>"))
    assert(!f.isWikiName?("WIKI"))
    assert(f.isWikiName?('WikiName/SubWikiName'))
    assert(f.isWikiName?('WikiName\SubWikiName'))
    assert(f.isWikiName?('/WikiName/SubWikiName'))
    assert(!f.isWikiName?('./WikiName/SubWikiName'))
    assert(!f.isWikiName?('/.WikiName/SubWikiName'))
    assert(!f.isWikiName?('/Wiki.Name/SubWikiName'))
    assert(!f.isWikiName?('WikiName/Notwikiname'))
    assert(!f.isWikiName?('Notwikiname/WikiName'))
    assert(!f.isWikiName?('WikiName/WikiName/Notwikiname'))
    assert(!f.isWikiName?('/'))
    assert(!f.isWikiName?('//'))
    # Should these be WikiNames?
    #  EmpACT
    #  HelP
    # ... they're not in the c2.com wiki
  end
end

class TestClWikiPageFormatter < TestBase
  def test_only_html
    assert(ClWiki::PageFormatter.only_html('<tag>'))
    assert(!ClWiki::PageFormatter.only_html('<tag'))
    assert(!ClWiki::PageFormatter.only_html('tag>'))
    assert(!ClWiki::PageFormatter.only_html('tag'))
    assert(!ClWiki::PageFormatter.only_html(''))
    assert(!ClWiki::PageFormatter.only_html('  '))
    assert(ClWiki::PageFormatter.only_html('  < t a g >  '))
    assert(!ClWiki::PageFormatter.only_html('<t>a<g>'))

    # if this passes, method is misnamed, now
    assert( ClWiki::PageFormatter.only_html('<h1>a</h1>'))
    assert( ClWiki::PageFormatter.only_html(' <h5> a </h5>  '))
    assert( ClWiki::PageFormatter.only_html(' <h5> <a href> </h5>  '))
    assert(!ClWiki::PageFormatter.only_html(' <h5> <a href> </h5> stuff '))
  end
end

class TestGlobalHitReducer < TestBase
  def test_global_hit_reducer
    # for global links, we want matches to be limited to exact matches.
    # If //RootPage/SubPage has seven children:
    #
    #   //RootPage/SubPage/ChildOne
    #   //RootPage/SubPage/ChildTwo
    #   ...
    #
    # and the content is SubPage, we don't want a global link to the
    # find results of SubPage, but a direct link to //RootPage/SubPage.
    # If there's also a //OtherPage/SubPage, then the global link in this
    # case will still go to Find Results.

    hits = ['//RootPage/SubPage', '//RootPage/SubPage/ChildOne']
    reduced = ClWiki::GlobalHitReducer.reduce_to_exact_if_exists('SubPage', hits)
    assert_equal(['//RootPage/SubPage'], reduced)

    reduced = ClWiki::GlobalHitReducer.reduce_to_exact_if_exists('SubPa', hits)
    assert_equal(hits, reduced)

    hits = ['//RootPage/SubPage', '//OtherPage/SubPage']
    reduced = ClWiki::GlobalHitReducer.reduce_to_exact_if_exists('SubPage', hits)
    assert_equal(hits, reduced)
  end
end
