require 'clwikipage'
require 'clwikitestbase'

# stub this out for testing
class ClWikiPage
  @@pageExists = false
  @@pageGloballyExists = false

  def ClWikiPage.set_page_exists(value)
    @@pageExists = value
  end

  def ClWikiPage.page_exists?(pageFullName)
    @@pageExists
  end
end

class TestClWikiPage < TestBase
  def testWikiPage
    newPage = ClWikiPage.new('/NewPage')
  end

  def doTestConvertToLink(pageName, pagePath='/FrontPage')
    f = ClWikiPageFormatter.new(nil, pagePath)
    fullPageName = f.expand_path(pageName, pagePath)
    ClWikiPage.set_page_exists(false)
    $wikiConf.editable = true
    assert_equal(
      pageName + "<a href=clwikicgi.rb?page=" + fullPageName + "&edit=true>?</a>",
      f.convertToLink(pageName))
    $wikiConf.editable = false
    assert_equal(
      pageName,
      f.convertToLink(pageName))
    ClWikiPage.set_page_exists(true)

    # now that links serve up a separate link for each page in the
    # hierarchy, testing this is cumbersome - and there's already
    # tests for testFormatLinkPages which exercise this same thing

    # assert_equal(
    #  "<a href=clwikicgi.rb?page=" + fullPageName + ">" + pageName + "</a>",
    #   f.convertToLink(pageName))
  end

  # refactor
    # these were all one method, but I had repeat pages and
    # needed setup/teardown around them. But, having them all be separate
    # methods makes it a bit awkward here -- eats up a lot of extra space --
    # I need methods to be created at run-time, or a sub-testcase object?
    # or just delete the ClWikiFile at the end of doTestConvertToLink
    def testConvertToLinkMain
      doTestConvertToLink("TestPage")
    end

    def testConvertToLinkSubBS
      doTestConvertToLink("TestPage\TestSubPage")
    end

    def testConvertToLinkSubFS
      doTestConvertToLink("TestPage/TestSubPage")
    end

    def testConvertToLinkBSSub
      doTestConvertToLink("\TestPage/TestSubPage")
    end

    def testConvertToLinkFSSub
      doTestConvertToLink("/TestPage/TestSubPage")
    end

    def testConvertToLinkFSSubSub
      doTestConvertToLink("/TestPage/TestSubPage\NotherSubPage")
    end

    def testConvertToLinkFSSubSub2
      doTestConvertToLink("/TestPage/TestSubPage/NotherSubPage")
    end

    def testConvertToLinkCollapsePath
      doTestConvertToLink("TestSubPage/NotherSubPage", "/TestPage/TestSubPage")
      doTestConvertToLink("SubPage/NotherSubPage", "/TestPage/SubPage/SubPage")
    end
  # end refactor

  # def test_page_expand_path
  #   assert_equal("/a/b/c",           ClWikiPage.expand_path("b/c", "/a/b/c/d/e"))
  #   assert_equal("/b/c",             ClWikiPage.expand_path("/b/c", "/a/b/c/d/e"))
  #   assert_equal("/a/b",             ClWikiPage.expand_path("b", "/a/b/c/d/e"))
  #   assert_equal("/a/b/c/f",         ClWikiPage.expand_path("b/c/f", "/a/b/c/d/e"))
  #   assert_equal("/a/b/c/d/e/m/n/o", ClWikiPage.expand_path("m/n/o", "/a/b/c/d/e"))
  #   assert_equal("/a/b/c/a/b/d",     ClWikiPage.expand_path("a/b/d", "/a/b/c/a/b/c"))
  #   assert_equal("/a/b",             ClWikiPage.expand_path("/a/b", "/"))
  #   assert_equal("/m/n",             ClWikiPage.expand_path("/m/n", "/a/b"))
  #   fail('need case insensitive tests...')
  # end

  def test_page_expand_path
    f = ClWikiPageFormatter.new
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

  def testGSubWords
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
    f = ClWikiPageFormatter.new(original)
    f.gsubWords { |word| actualResults << word }
    assert_equal(expectedResults, actualResults)
  end

  def doTestFormatLinks(content, expectedContent, currentPagePath='/FrontPage', pageExists=true, pageGloballyExists=false)
    if pageGloballyExists
      globalFullPageName = '/GlobalRoot/' + content
    else
      globalFullPageName = nil
    end

    $wikiConf.editable = true
    f = ClWikiPageFormatter.new(content, currentPagePath)
    ClWikiPage.set_page_exists(pageExists)
    assert_equal(expectedContent, f.formatLinks, "content: #{content} pageExists: #{pageExists} pageGloballyExists: #{pageGloballyExists} editable")

    $wikiConf.editable = false
    f = ClWikiPageFormatter.new(content, currentPagePath)
    ClWikiPage.set_page_exists(pageExists)
    if !pageExists
      assert_equal(content, f.formatLinks, "content: #{content} pageExists: #{pageExists} pageGloballyExists: #{pageGloballyExists} not editable")
    else
      assert_equal(expectedContent, f.formatLinks, "content: #{content} pageExists: #{pageExists} pageGloballyExists: #{pageGloballyExists} not editable")
    end
  end

  def testFormatLinkPages
                      # content, expectedContent, currentPagePath, pageExists
    doTestFormatLinks('TestPage', "TestPage<a href=clwikicgi.rb?page=/TestPage&edit=true>?</a>", '/FrontPage', false)
    doTestFormatLinks('TestPage', "<a href=clwikicgi.rb?page=/TestPage>TestPage</a>", '/FrontPage', true)

    # this is an important test. The scanning includes some punctuation
    # as word characters, but not others. Comma ain't one of them, so this
    # makes sure the division of characters is working right.
    doTestFormatLinks('TestPage,', "<a href=clwikicgi.rb?page=/TestPage>TestPage</a>,", '/FrontPage', true)

    # the current parsing skips over the brackets, so the tags
    # are returned intact. IE 5 just ignores them.
    # In the future I need to code no wiki links within
    # brackets which means parsing them.
    doTestFormatLinks('<NoWikiLinks>TestPage</NoWikiLinks>', "TestPage")

    # No WikiLinks within < >, to avoid problems with href
    doTestFormatLinks('<a href="www.NotAWikiPage.com">some link</a>', '<a href="www.NotAWikiPage.com">some link</a>')

    doTestFormatLinks('/TestPage',
                      "/<a href=clwikicgi.rb?page=/FrontPage/TestPage>TestPage</a>",
                      '/FrontPage', true)
    doTestFormatLinks('TestPage/TestSubPage',
                      "<a href=clwikicgi.rb?page=/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/TestPage/TestSubPage>TestSubPage</a>",
                      '/FrontPage', true)
    doTestFormatLinks('TestPage/TestSubPage',
                      "<a href=clwikicgi.rb?page=/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/TestPage/TestSubPage>TestSubPage</a>",
                      '/SubRoot', true)
    doTestFormatLinks('/TestPage/TestSubPage',
                      "/<a href=clwikicgi.rb?page=/SubRoot/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/SubRoot/TestPage/TestSubPage>TestSubPage</a>",
                      '/SubRoot', true)
    doTestFormatLinks('//TestPage/TestSubPage',
                      "//<a href=clwikicgi.rb?page=/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/TestPage/TestSubPage>TestSubPage</a>",
                      '/SubRoot', true)
    doTestFormatLinks('TestPage/TestSubPage',
                      "<a href=clwikicgi.rb?page=/SubRootA/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/SubRootA/TestPage/TestSubPage>TestSubPage</a>",
                      '/SubRootA/SubRootB', true)
    doTestFormatLinks('/TestPage/TestSubPage',
                      "/<a href=clwikicgi.rb?page=/SubRootA/SubRootB/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/SubRootA/SubRootB/TestPage/TestSubPage>TestSubPage</a>",
                      '/SubRootA/SubRootB', true)
    doTestFormatLinks('//TestPage/TestSubPage',
                      "//<a href=clwikicgi.rb?page=/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/TestPage/TestSubPage>TestSubPage</a>",
                      '/SubRootA/SubRootB', true)
    doTestFormatLinks('TestPage\TestSubPage',
                      "<a href=clwikicgi.rb?page=/TestPage>TestPage</a>/<a href=clwikicgi.rb?page=/TestPage/TestSubPage>TestSubPage</a>",
                      '/FrontPage', true)
    doTestFormatLinks('TestPage',
                      "<a href=clwikicgi.rb?page=/SubRootA/SubRootB/TestPage>TestPage</a>",
                      '/SubRootA/SubRootB/TestPage', true)
    doTestFormatLinks('TestPage',
                      "TestPage<a href=clwikicgi.rb?page=/SubRootA/SubRootB/TestPage&edit=true>?</a>",
                      '/SubRootA/SubRootB/MasterTestPage', false)
  end

  def testIsWikiName
    f = ClWikiPageFormatter.new
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
    assert(ClWikiPageFormatter.only_html('<tag>'))
    assert(!ClWikiPageFormatter.only_html('<tag'))
    assert(!ClWikiPageFormatter.only_html('tag>'))
    assert(!ClWikiPageFormatter.only_html('tag'))
    assert(!ClWikiPageFormatter.only_html(''))
    assert(!ClWikiPageFormatter.only_html('  '))
    assert(ClWikiPageFormatter.only_html('  < t a g >  '))
    assert(!ClWikiPageFormatter.only_html('<t>a<g>'))

    # if this passes, method is misnamed, now
    assert( ClWikiPageFormatter.only_html('<h1>a</h1>'))
    assert( ClWikiPageFormatter.only_html(' <h5> a </h5>  '))
    assert( ClWikiPageFormatter.only_html(' <h5> <a href> </h5>  '))
    assert(!ClWikiPageFormatter.only_html(' <h5> <a href> </h5> stuff '))
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
    reduced = GlobalHitReducer.reduce_to_exact_if_exists('SubPage', hits)
    assert_equal(['//RootPage/SubPage'], reduced)

    reduced = GlobalHitReducer.reduce_to_exact_if_exists('SubPa', hits)
    assert_equal(hits, reduced)

    hits = ['//RootPage/SubPage', '//OtherPage/SubPage']
    reduced = GlobalHitReducer.reduce_to_exact_if_exists('SubPage', hits)
    assert_equal(hits, reduced)
  end
end
