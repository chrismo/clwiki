# frozen_string_literal: true

require_relative '../spec_helper'

require 'tmpdir'

RSpec.describe ClWiki::SessionsController do
  describe 'use authentication' do
    before do
      $wiki_path = Dir.mktmpdir
      $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_NO
      $wiki_conf.use_authentication = true

      @routes = ClWiki::Engine.routes

      AuthFixture.create_test_user
    end

    after do
      FileUtils.remove_entry_secure $wiki_path
      $wiki_path = $wiki_conf.wiki_path
      $wiki_conf.editable = true # "globals #{'rock'.sub(/ro/, 'su')}!"
      $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_NO
    end

    it 'login invalid username' do
      post :create, params: {username: 'testy', password: 'blue pill'}
      assert_redirected_to login_path
    end

    it 'login invalid password' do
      post :create, params: {username: 'testy', password: 'blue pill'}
      assert_redirected_to login_path
    end

    it 'login valid' do
      post :create, params: {username: 'testy', password: 'red pill'}
      assert_redirected_to root_path
    end
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

    it 'get login redirects to root' do
      post :new
      assert_redirected_to root_path
    end

    it 'post login redirects to root' do
      post :create, params: {username: 'testy', password: 'blue pill'}

      assert_redirected_to root_path
    end
  end
end
