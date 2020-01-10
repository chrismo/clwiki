# frozen_string_literal: true

require_relative '../spec_helper'

require 'tmpdir'

RSpec.describe ClWiki::SessionsController do
  describe 'use authentication' do
    before do
      $wiki_path = Dir.mktmpdir
      $wiki_conf.use_authentication = true

      @routes = ClWiki::Engine.routes

      @user = AuthFixture.create_test_user
      $wiki_conf.owner = @user.username
    end

    after do
      FileUtils.remove_entry_secure $wiki_path
      $wiki_path = $wiki_conf.wiki_path
      $wiki_conf.editable = true # "globals #{'rock'.sub(/ro/, 'su')}!"
      end

    it 'login invalid username' do
      post :create, params: {username: @user.name, password: 'blue pill'}
      assert_redirected_to login_path
    end

    it 'login invalid password' do
      post :create, params: {username: @user.name, password: 'blue pill'}
      assert_redirected_to login_path
    end

    it 'login valid' do
      post :create, params: {username: @user.name, password: 'red pill'}
      assert_redirected_to root_path
    end
  end

  describe 'do not use authentication' do
    before do
      $wiki_path = Dir.mktmpdir
      $wiki_conf.use_authentication = false

      @routes = ClWiki::Engine.routes

      @user = AuthFixture.create_test_user
      $wiki_conf.owner = @user.name
    end

    after do
      FileUtils.remove_entry_secure $wiki_path
      $wiki_path = $wiki_conf.wiki_path
      $wiki_conf.editable = true # "globals #{'rock'.sub(/ro/, 'su')}!"
      end

    it 'get login redirects to root' do
      post :new
      assert_redirected_to root_path
    end

    it 'post login redirects to root' do
      post :create, params: {username: @user.name, password: 'blue pill'}

      assert_redirected_to root_path
    end
  end
end
