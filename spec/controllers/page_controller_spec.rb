# frozen_string_literal: true
require_relative '../spec_helper'

require 'tmpdir'

# rubocop:disable Lint/Void
RSpec.describe ClWiki::PageController do
  describe 'use authentication' do
    before do
      $wiki_path = Dir.mktmpdir
      $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_NO
      $wiki_conf.use_authentication = true

      @routes = ClWiki::Engine.routes

      user = AuthFixture.create_test_user
      get :show, params: {}, session: {username: user.username}
    end

    after do
      FileUtils.remove_entry_secure $wiki_path
      $wiki_path = $wiki_conf.wiki_path
      $wiki_conf.editable = true # "globals #{'rock'.sub(/ro/, 'su')}!"
      $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_NO
    end

    it 'should render /FrontPage by default' do
      get :show

      assert_redirected_to page_show_path(page_name: 'FrontPage')
    end

    it 'should render /NewPage with new content prompt' do
      get :show, params: {page_name: 'NewPage'}

      page = assigns(:page)
      page.full_name.should == '/NewPage'
      page.content.should =~ /Describe.*NewPage.*here/
    end

    it 'should allow editing of a page' do
      get :edit, params: {page_name: 'NewPage'}

      page = assigns(:page)
      page.full_name.should == '/NewPage'
      page.raw_content.should == 'Describe NewPage here.'
    end

    it 'should accept posted changes to a page' do
      get :edit, params: {page_name: 'NewPage'}
      page = assigns(:page)

      post :update, params: {page_name: 'NewPage', page_content: 'NewPage content', client_mod_time: page.mtime.to_i}

      page = assigns(:page)
      page.read_raw_content
      page.raw_content.should == 'NewPage content'
      assert_redirected_to page_show_path(page_name: 'NewPage', host: 'foo.com')
    end

    it 'should also accept posted changes to a page and continue editing' do
      get :edit, params: {page_name: 'NewPage'}
      page = assigns(:page)

      post :update, params: {page_name: 'NewPage', page_content: 'NewPage content', client_mod_time: page.mtime.to_i, save_and_edit: true}

      page = assigns(:page)
      page.read_raw_content
      page.raw_content.should == 'NewPage content'
      assert_redirected_to page_edit_path(page_name: 'NewPage')
    end

    it 'should handle multiple edit situation' # see legacy test test_multi_user_edit below

    it 'should redirect to front page on bad page name' do
      get :show, params: {page_name: 'notavalidname'}

      assert_redirected_to page_show_path(page_name: 'FrontPage')
    end

    it 'should redirect to front page on non-existent page if not editable' do
      $wiki_conf.editable = false
      get :show, params: {page_name: 'NewPage'}

      assert_redirected_to page_show_path(page_name: 'FrontPage')
    end

    it 'should render find entry page' do
      get :find

      assigns(:formatter).should be_a ClWiki::PageFormatter
      assigns(:search_text).should.nil?
      assigns(:results).should == []
    end

    it 'should render find page with results without index' do
      $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_NO
      PageFixture.write_page('BarFoo', 'foobar')
      PageFixture.write_page('BaaRamEwe', 'sheep foobar')

      post :find, params: {search_text: 'sheep'}

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

      get :recent, format: 'rss'

      assigns(:pages).map(&:full_name).should == ['FooBar']
    end
  end

  def build_expected_content(full_page_name, content = '')
    f = ClWiki::PageFormatter.new(content, full_page_name)
    page_name = File.split(full_page_name)[-1]
    expected_content = f.header(full_page_name)

    if content.empty?
      expected_content << 'Describe <a href=clwikicgi.rb?page=' + full_page_name + '>' + page_name + '</a> here.<br>'
    else
      expected_content << content
    end

    expected_content << f.footer(full_page_name)
  end

  describe 'do not use authentication' do
    before do
      $wiki_path = Dir.mktmpdir
      $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_NO
      $wiki_conf.use_authentication = false

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

      assert_redirected_to page_show_path(page_name: 'FrontPage')
    end
  end
end
# rubocop:enable Lint/Void
