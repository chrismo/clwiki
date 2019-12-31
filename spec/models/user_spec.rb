# frozen_string_literal: true

require_relative '../spec_helper'

require 'tmpdir'

RSpec.describe ClWiki::User do
  before do
    $wiki_path = Dir.mktmpdir
    $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_NO
  end

  after do
    FileUtils.remove_entry_secure $wiki_path
    $wiki_path = $wiki_conf.wiki_path
    $wiki_conf.editable = true # "globals #{'rock'.sub(/ro/, 'su')}!"
    $wiki_conf.useIndex = ClWiki::Configuration::USE_INDEX_NO
  end

  it 'persistence and authentication' do
    user = ClWiki::User.new
    refute user.valid?

    user.username = 'test-user'
    user.password = 'foobar'

    assert user.valid?
    user.save

    loaded = ClWiki::User.find('test-user')
    assert loaded
    refute loaded.authenticate('foo')
    assert loaded.authenticate('foobar')
  end
end
