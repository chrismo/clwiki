require_relative '../spec_helper'

require 'tmpdir'

describe ClWiki::PageController do
  before do
    $wiki_path = Dir.mktmpdir
    $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_NO

    @routes = ClWiki::Engine.routes
  end

  after do
    FileUtils.remove_entry_secure $wiki_path
    $wiki_path = $wiki_conf.wiki_path
    $wiki_conf.editable = true # "globals #{'rock'.sub(/ro/, 'su')}!"
    $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_NO
  end

  it 'should render /FrontPage by default' do
    get :show

    assert_redirected_to page_show_path(:page_name => 'FrontPage')
  end

  it 'should render /NewPage with new content prompt' do
    get :show, params: {:page_name => 'NewPage'}

    page = assigns(:page)
    page.full_name.should == '/NewPage'
    page.content.should =~ /Describe.*NewPage.*here/
  end

  it 'should allow editing of a page' do
    get :edit, params: {:page_name => 'NewPage'}

    page = assigns(:page)
    page.full_name.should == '/NewPage'
    page.raw_content.should == 'Describe NewPage here.'
  end

  it 'should accept posted changes to a page' do
    get :edit, params: {:page_name => 'NewPage'}
    page = assigns(:page)

    post :update, params: {:page_name => 'NewPage', :page_content => 'NewPage content', :client_mod_time => page.mtime.to_i}

    page = assigns(:page)
    page.read_raw_content
    page.raw_content.should == 'NewPage content'
    assert_redirected_to page_show_path(:page_name => 'NewPage', :host => 'foo.com')
  end

  it 'should also accept posted changes to a page and continue editing' do
    get :edit, params: {:page_name => 'NewPage'}
    page = assigns(:page)

    post :update, params: {:page_name => 'NewPage', :page_content => 'NewPage content', :client_mod_time => page.mtime.to_i, :save_and_edit => true}

    page = assigns(:page)
    page.read_raw_content
    page.raw_content.should == 'NewPage content'
    assert_redirected_to page_edit_path(:page_name => 'NewPage')
  end

  it 'should handle multiple edit situation' # see legacy test test_multi_user_edit below

  it 'should redirect to front page on bad page name' do
    get :show, params: {:page_name => 'notavalidname'}

    assert_redirected_to page_show_path(:page_name => 'FrontPage')
  end

  it 'should redirect to front page on non-existent page if not editable' do
    $wiki_conf.editable = false
    get :show, params: {:page_name => 'NewPage'}

    assert_redirected_to page_show_path(:page_name => 'FrontPage')
  end

  it 'should render find entry page' do
    get :find

    assigns(:formatter).should be_a ClWiki::PageFormatter
    assigns(:search_text).should == nil
    assigns(:results).should == []
  end

  it 'should render find page with results without index' do
    $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_NO
    PageFixture.write_page('BarFoo', 'foobar')
    PageFixture.write_page('BaaRamEwe', 'sheep foobar')

    post :find, params: {:search_text => 'sheep'}

    assigns(:formatter).should be_a ClWiki::PageFormatter
    assigns(:search_text).should == 'sheep'
    assigns(:results).should == ["<a href='BaaRamEwe'>BaaRamEwe</a>"]
  end

  it 'should render recent pages view' do
    PageFixture.write_page('FooBar', 'foobar')
    sleep 0.1
    PageFixture.write_page('BazQuux', 'bazquux')
    $wiki_conf.publishTag = nil

    get :recent

    assigns(:pages).map(&:full_name).should == ['BazQuux', 'FooBar']
  end

  it 'should render recent pages view with matching publish tags' do
    PageFixture.write_page('FooBar', "<publish>\nfoobar")
    sleep 0.1
    PageFixture.write_page('BazQuux', 'bazquux')
    $wiki_conf.publishTag = '<publish>'

    get :recent

    assigns(:pages).map(&:full_name).should == ['FooBar']
    # view should call get_header without footer, so those shouldn't be mixed into content
    assigns(:pages)[0].content.should_not start_with "<div class='wikiHeader'>"
  end

  it 'should render recent pages view with rss format' do
    PageFixture.write_page('FooBar', "<publish>\nfoobar")
    sleep 0.1
    PageFixture.write_page('BazQuux', 'bazquux')
    $wiki_conf.publishTag = '<publish>'

    get :recent, :format => 'rss'

    assigns(:pages).map(&:full_name).should == ['FooBar']
  end
end

def build_expected_content(full_page_name, content = "")
  f = ClWiki::PageFormatter.new(content, full_page_name)
  page_name = File.split(full_page_name)[-1]
  expected_content = f.header(full_page_name)

  if content.empty?
    expected_content << "Describe <a href=clwikicgi.rb?page=" + full_page_name + ">" + page_name + "</a> here.<br>"
  else
    expected_content << content
  end

  expected_content << f.footer(full_page_name)
end

=begin

class TestClWiki < TestBase
  def set_up
    super
    @clWiki = ClWiki.new(@test_wiki_path)
    sleep 1
  end

  def doTestNewPageThruWiki(pageNameArray, separator)
    @clWiki = ClWiki.new(@test_wiki_path)
    fullPageName = separator + pageNameArray.join(separator)
    fullPageName = ClWiki::Util.convertToNativePath(fullPageName)
    actualContent = @clWiki.displayPage(fullPageName).content

    pageName = pageNameArray.last
    assert_equal(buildExpectedContent(fullPageName), actualContent,
      'pageNameArray: ' + pageNameArray.inspect + ' separator: ' + separator)
  end

  def testNewPageThruWiki
    # this is getting tedious to keep up...
    # doTestNewPageThruWiki(['NewPage'], '/')
    # doTestNewPageThruWiki(['NewPage', 'NewSubPage'], "\\")
    # doTestNewPageThruWiki(['NewPage', 'NewSubPage'], '/')
    # doTestNewPageThruWiki(['NewSubPage'], "\\")
    # doTestNewPageThruWiki(['NewSubPage'], '/')
  end

  def testDisplayPage
    @clWiki = ClWiki.new(@test_wiki_path)
    testPage = '/TestPage'
    wikiPageModTime = @clWiki.displayPage(testPage).modTime
    updateContent = "Sample text before\n\n" +
      "<table>\n<tr>\n<td>testdata</td>\n</tr>\n</table>\n" +
      "Sample text <a href='http://clabs.org'>after</a>\n"

    readContent = "Sample text before<br><br>" +
      "<table>\n<tr>\n<td>testdata</td><br></tr>\n</table>\n" +
      "Sample text <a href='http://clabs.org'>after</a><br>"
    @clWiki.updatePage('/TestPage', wikiPageModTime, updateContent)
    assert_equal(buildExpectedContent(testPage, readContent),
      @clWiki.displayPage(testPage).content)
  end

  def testDisplayEditPage
    @clWiki = ClWiki.new(@test_wiki_path)
    testPage = '/TestPage'
    content = @clWiki.displayPageEdit(testPage)
    assert(content =~ /Describe TestPage here/)
  end

  def testFrontPageIfBadName
    assert_equal("/FrontPage", @clWiki.frontPageIfBadName("/FrontPage"))
    assert_equal("/FrontPage", @clWiki.frontPageIfBadName(""))
  end

  def buildExpectedContent(fullPageName, content = "")
    f = ClWikiPageFormatter.new(content, fullPageName)
    pageName = File.split(fullPageName)[-1]
    expectedContent = f.header(fullPageName)

    if content.empty?
      expectedContent << "Describe <a href=clwikicgi.rb?page=" + fullPageName + ">" + pageName + "</a> here.<br>"
    else
      expectedContent << content
    end

    expectedContent << f.footer(fullPageName)
  end

  def test_multi_user_edit
    exit
    # clwikifiletest has a multi user test

    testPageName = "/UpdatePage"
    # A and B read, same contents sent to both users
    expectedContent = buildExpectedContent(testPageName)
    wikiPageA = @clWiki.displayPage(testPageName)
    wikiPageB = @clWiki.displayPage(testPageName)
    assert_equal(expectedContent, wikiPageA.content)
    assert_equal(expectedContent, wikiPageB.content)
    modTimeA = wikiPageA.modTime
    modTimeB = wikiPageB.modTime

    sleep 3.5 # to ensure mtime changes. (lesser time sometimes doesn't work)

    @clWiki.updatePage(testPageName, modTimeA, "user A content")

    begin
      @clWiki.updatePage(testPageName, modTimeB, "user B content")
      assert(false, "Expected exception did not occur.")
    rescue ClWiki::FileModifiedSinceRead
      # don't do anything, it's what should happen
    end

    # a bit of a tedious check
    # assert_equal(buildExpectedContent(testPageName, "user A content<br>"),
    #  @clWiki.displayPage(testPageName).content)
  end

  # def testWordWrap
  #   assert_equal("this \nis a \nword \nwrap \ntest",
  #     @clWiki.wordWrap("this is a word wrap test", 4), "wrap at 4")
  #   assert_equal("this \nis a \nword \nwrap \ntest",
  #     @clWiki.wordWrap("this is a word wrap test", 5), "wrap at 5")
  #   assert_equal("this is \na word \nwrap \ntest",
  #     @clWiki.wordWrap("this is a word wrap test", 7), "wrap at 7")
  #   assert_equal("this \nis a word \nwrap test",
  #     @clWiki.wordWrap("this \nis a word wrap test", 10), "wrap at 10")

  #   assert_equal("this is a word wrap test",
  #     @clWiki.wordWrap("this is a word wrap test", 80), "wrap at 80")
  # end
end

class TestClWikiConf < TestBase
  def set_up
    super
    @testConfFile = @test_wiki_path + '/testwiki.conf.xml'
  end

  def testReadPath
    f = File.new(@testConfFile, File::CREAT|File::TRUNC|File::RDWR)
    begin
      xml = <<-XML
        <ClWikiConf>
          <wikiPath>#{@test_wiki_path}</wikiPath>
        </ClWikiConf>
      XML
      f.puts(xml)
      f.flush
    ensure
      f.close unless f.nil?
    end
    clWiki = ClWiki.new("", @testConfFile)
    assert_equal(@test_wiki_path, clWiki.wikiPath)
  end
end

=end
