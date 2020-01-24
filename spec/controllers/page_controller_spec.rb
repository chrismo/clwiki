# frozen_string_literal: true

require_relative '../spec_helper'

require 'tmpdir'

# rubocop:disable Lint/Void
RSpec.describe ClWiki::PageController do
  render_views

  describe 'use authentication' do
    before do
      @restore_wiki_path = $wiki_conf.wiki_path
      $wiki_conf.wiki_path = '/tmp/test_wiki'
      $wiki_conf.use_authentication = true

      @routes = ClWiki::Engine.routes

      @user = AuthFixture.create_test_user
      ClWiki::MemoryIndexer.instance(page_owner: @user)
      get :show, params: {}, session: {username: @user.username,
                                       encryption_key: Base64.encode64(@user.encryption_key)}
    end

    after do
      ClWiki::MemoryIndexer.instance_variable_set('@instance', nil)
      FileUtils.remove_entry_secure $wiki_conf.wiki_path
      $wiki_conf.wiki_path = @restore_wiki_path
      $wiki_conf.editable = true # "globals #{'rock'.sub(/ro/, 'su')}!"
      $indexer = nil
    end

    it 'should render /FrontPage by default' do
      get :show

      assert_redirected_to page_show_path(page_name: 'FrontPage')
    end

    it 'should render /NewPage with new content prompt' do
      get :show, params: {page_name: 'NewPage'}

      page = assigns(:page)
      page.page_name.should == 'NewPage'
      page.content.should =~ /Describe.*NewPage.*here/
    end

    it 'should render link to other pages properly' do
      PageFixture.write_page('TargetPage', 'content', owner: @user)
      PageFixture.write_page('SourcePage', 'TargetPage', owner: @user)

      get :show, params: {page_name: 'SourcePage'}

      assert_select ".wikiBody a[href='TargetPage']"
    end

    it 'should allow editing of a page' do
      get :edit, params: {page_name: 'NewPage'}

      page = assigns(:page)
      page.page_name.should == 'NewPage'
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
      PageFixture.write_page('BarFoo', 'foobar', owner: @user)
      PageFixture.write_page('BaaRamEwe', 'sheep foobar', owner: @user)

      post :find, params: {search_text: 'sheep'}

      assigns(:formatter).should be_a ClWiki::PageFormatter
      assigns(:search_text).should == 'sheep'
      assigns(:results).should == ["<a href='BaaRamEwe'>BaaRamEwe</a>"]
    end

    it 'should render recent pages view' do
      PageFixture.write_page('FooBar', 'foobar', owner: @user)
      sleep 0.1
      PageFixture.write_page('BazQuux', 'bazquux', owner: @user)
      $wiki_conf.publishTag = nil

      get :recent

      assigns(:pages).map(&:page_name).sort.should == ['BazQuux', 'FooBar']
    end

    it 'should render recent pages view with matching publish tags' do
      PageFixture.write_page('FooBar', "<publish>\nfoobar", owner: @user)
      sleep 0.1
      PageFixture.write_page('BazQuux', 'bazquux', owner: @user)
      $wiki_conf.publishTag = '<publish>'

      get :recent

      assigns(:pages).map(&:page_name).should == ['FooBar']
      # view should call get_header without footer, so those shouldn't be mixed into content
      assigns(:pages)[0].content.should_not start_with "<div class='wikiHeader'>"
    end

    it 'should render recent pages view with rss format' do
      PageFixture.write_page('FooBar', "<publish>\nfoobar", owner: @user)
      sleep 0.1
      PageFixture.write_page('BazQuux', 'bazquux', owner: @user)
      $wiki_conf.publishTag = '<publish>'

      get :recent, format: 'rss'

      assigns(:pages).map(&:page_name).should == ['FooBar']
    end

    it 'should allow toggling on and off encrypted contents' do
      get :edit, params: {page_name: 'NewEncryptedPage'}
      page = assigns(:page)
      assert_select 'label.findDetails'

      post :update, params: {page_name: 'NewEncryptedPage',
                             page_content: 'this should be encrypted on disk',
                             client_mod_time: page.mtime.to_i,
                             encrypt: 'yes'}

      page = assigns(:page)
      page.read_raw_content
      page.raw_content.should == 'this should be encrypted on disk'
      File.read(page.file_full_path_and_name, mode: 'rb').should_not =~ /should be encrypted/

      post :update, params: {page_name: 'NewEncryptedPage',
                             page_content: 'this should not be encrypted on disk',
                             client_mod_time: page.mtime.to_i}

      page = assigns(:page)
      page.read_raw_content
      page.raw_content.should == 'this should not be encrypted on disk'
      File.read(page.file_full_path_and_name, mode: 'rb').should =~ /should not be encrypted/
    end

    it 'should default encrypted UI to on if configured' do
      get :edit, params: {page_name: 'ANewPage'}
      assert_select 'input[type=checkbox][name=encrypt]' do |elements|
        refute elements.first.attributes.key?('checked')
      end

      $wiki_conf.encryption_default = true
      get :edit, params: {page_name: 'AnotherNewPage'}
      assert_select 'input[type=checkbox][name=encrypt]' do |elements|
        assert elements.first.attributes.key?('checked')
      end
    end
  end

  def build_expected_content(full_page_name, content = '')
    f = ClWiki::PageFormatter.new(content, full_page_name)
    page_name = File.split(full_page_name)[-1]
    expected_content = f.header(full_page_name)

    if content.empty?
      content = "Describe <a href=clwikicgi.rb?page=#{full_page_name}>#{page_name}</a> here.<br>"
    end

    expected_content << content
    expected_content << f.footer(full_page_name)
  end

  describe 'do not use authentication' do
    before do
      @restore_wiki_path = $wiki_conf.wiki_path
      $wiki_conf.wiki_path = Dir.mktmpdir
      $wiki_conf.use_authentication = false

      @routes = ClWiki::Engine.routes
    end

    after do
      FileUtils.remove_entry_secure $wiki_conf.wiki_path
      $wiki_conf.wiki_path = @restore_wiki_path
      $wiki_conf.editable = true # "globals #{'rock'.sub(/ro/, 'su')}!"
    end

    it 'should render /FrontPage by default' do
      get :show

      assert_redirected_to page_show_path(page_name: 'FrontPage')
    end

    it 'should not show encrypting UI on page edit' do
      get :edit, params: {page_name: 'NewPage'}

      assert_select 'label.findDetails', false
      assert_select 'input[type=checkbox][name=encrypt]', false
    end
  end
end
# rubocop:enable Lint/Void
