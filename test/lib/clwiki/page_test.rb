require_relative 'clwiki_test_helper'
require 'page'
require 'tmpdir'

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
    ClWiki::Page.new('/NewPage')
  end

  def do_test_convert_to_link(pageName, pagePath='/FrontPage')
    f = ClWiki::PageFormatter.new(nil, pagePath)
    # fullPageName = f.expand_path(pageName, pagePath)
    ClWiki::Page.set_page_exists(false)
    $wiki_conf.editable = true
    assert_equal(
      pageName + "<a href='#{pageName}/edit'>?</a>",
      f.convert_to_link(pageName))
    $wiki_conf.editable = false
    assert_equal(
      pageName,
      f.convert_to_link(pageName))
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

  def test_gsub_words
    original =
        'test page PageName ' +
            'PageName/SubPage PageName\SubPage\SubPage ' +
            '/PageName/SubPage \PageName\SubPage\SubPage ' +
            'test.thing test, <tagger> </tagger> oops>whoops ' +
            'oops<thing>bleh hen<butter '

    expected_results =
        %w(test page PageName
           PageName SubPage PageName SubPage SubPage PageName SubPage PageName SubPage SubPage
           test thing test <tagger> </tagger> oops whoops
           oops <thing> bleh hen butter)

    actual_results = Array.new
    f = ClWiki::PageFormatter.new(original)
    f.gsub_words { |word| actual_results << word }
    assert_equal(expected_results, actual_results)
  end

  def do_test_format_links(content, expected_content, page_exists=true)
    $wiki_conf.editable = true
    f = ClWiki::PageFormatter.new(content, nil)
    ClWiki::Page.set_page_exists(page_exists)
    assert_equal(expected_content, f.format_links, "content: #{content} page_exists: #{page_exists} editable")

    $wiki_conf.editable = false
    f = ClWiki::PageFormatter.new(content, nil)
    ClWiki::Page.set_page_exists(page_exists)
    if page_exists
      assert_equal(expected_content, f.format_links, "content: #{content} page_exists: #{page_exists} not editable")
    else
      assert_equal(content, f.format_links, "content: #{content} page_exists: #{page_exists} not editable")
    end
  end

  def test_format_link_pages
    do_test_format_links('TestPage', "TestPage<a href='TestPage/edit'>?</a>", false)
    do_test_format_links('TestPage', "<a href='TestPage'>TestPage</a>", true)

    # this is an important test. The scanning includes some punctuation
    # as word characters, but not others. Comma ain't one of them, so this
    # makes sure the division of characters is working right.
    do_test_format_links('TestPage,', "<a href='TestPage'>TestPage</a>,", true)

    # the current parsing skips over the brackets, so the tags
    # are returned intact. IE 5 just ignores them.
    # In the future I need to code no wiki links within
    # brackets which means parsing them.
    do_test_format_links('<NoWikiLinks>TestPage</NoWikiLinks>', "TestPage")

    # No WikiLinks within < >, to avoid problems with href
    do_test_format_links('<a href="www.NotAWikiPage.com">some link</a>', '<a href="www.NotAWikiPage.com">some link</a>')

    do_test_format_links('/TestPage', "/<a href='TestPage'>TestPage</a>", true)
    do_test_format_links('TestPage/TestSubPage', "<a href='TestPage'>TestPage</a>/<a href='TestSubPage'>TestSubPage</a>", true)
    do_test_format_links('/TestPage/TestSubPage', "/<a href='TestPage'>TestPage</a>/<a href='TestSubPage'>TestSubPage</a>", true)
    do_test_format_links('//TestPage/TestSubPage', "//<a href='TestPage'>TestPage</a>/<a href='TestSubPage'>TestSubPage</a>", true)
  end

  def test_is_wiki_name
    f = ClWiki::PageFormatter.new
    assert(f.is_wiki_name?("WikiName"))
    assert(!f.is_wiki_name?("WikiName,"))
    assert(!f.is_wiki_name?("Wikiname"))
    assert(!f.is_wiki_name?("wIkiName"))
    assert(!f.is_wiki_name?("<h1>wikiName</h1><br>Other"))
    assert(!f.is_wiki_name?("<WikiName>"))
    assert(!f.is_wiki_name?("WIKI"))
    assert(f.is_wiki_name?('WikiName/SubWikiName'))
    assert(f.is_wiki_name?('WikiName\SubWikiName'))
    assert(f.is_wiki_name?('/WikiName/SubWikiName'))
    assert(!f.is_wiki_name?('./WikiName/SubWikiName'))
    assert(!f.is_wiki_name?('/.WikiName/SubWikiName'))
    assert(!f.is_wiki_name?('/Wiki.Name/SubWikiName'))
    assert(!f.is_wiki_name?('WikiName/Notwikiname'))
    assert(!f.is_wiki_name?('Notwikiname/WikiName'))
    assert(!f.is_wiki_name?('WikiName/WikiName/Notwikiname'))
    assert(!f.is_wiki_name?('/'))
    assert(!f.is_wiki_name?('//'))
  end

  def test_custom_formatter
    page = ClWiki::Page.new('MyPage')
    page.update_content("[]\n[/]", page.mtime)
    assert_match(/#{Regexp.escape("<blockquote>\n</blockquote>")}/, page.read_content(false))
  end

  def test_custom_formatter_path_config
    Dir.mktmpdir do |dir|
      begin
        $wiki_conf.custom_formatter_load_path << dir
        File.open(File.join(dir, 'format.reverser.rb'), 'w') do |f|
          f.print <<-RUBY
          class ReverseText < ClWiki::CustomFormatter
            def ReverseText.match_re
              /.*/
            end

            def ReverseText.format_content(content, page)
              if content
                content.reverse
              end
            end
          end

          ClWiki::CustomFormatters.instance.register(ReverseText)
          RUBY
        end
        page = ClWiki::Page.new('RevPage')
        page.update_content("awesome", page.mtime)
        assert_match(/emosewa/, page.read_content(false))
      ensure
        ClWiki::CustomFormatters.instance.unregister(ReverseText)
        Object.send(:remove_const, :ReverseText)
        $wiki_conf.custom_formatter_load_path.delete(dir)
      end
    end
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
