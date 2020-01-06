# frozen_string_literal: true

require_relative '../spec_helper'

require 'tmpdir'

RSpec.describe ClWiki::ApplicationController, type: :request do
  before do
    @restore_wiki_path = $wiki_path
    $wiki_path = Dir.mktmpdir
    $wiki_conf.wiki_path = $wiki_path
    $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_MEMORY
    $wiki_conf.use_authentication = true

    @routes = ClWiki::Engine.routes

    AuthFixture.create_test_user
  end

  after do
    FileUtils.remove_entry_secure $wiki_conf.wiki_path
    $wiki_path = @restore_wiki_path
    $wiki_conf.wiki_path = $wiki_path
    $wiki_conf.editable = true # "globals #{'rock'.sub(/ro/, 'su')}!"
    $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_MEMORY
    $wiki_conf.use_authentication = true
  end

  describe 'use authentication' do
    it 'should redirect if not logged in' do
      get root_path
      assert_redirected_to login_path
    end

    it 'login and nav to home' do
      get login_path
      assert_template :new

      post login_path, params: {username: 'testy', password: 'red pill'}
      assert_redirected_to root_path
    end
  end

  describe 'do not use authentication' do
    it 'should not care if not logged in' do
      $wiki_conf.use_authentication = false

      get page_show_path(page_name: 'FrontPage')
      assert_template :show
    end
  end
end
