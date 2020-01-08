# frozen_string_literal: true

require_relative '../spec_helper'

require 'tmpdir'

RSpec.describe ClWiki::User do
  before do
    $wiki_path = Dir.mktmpdir
    end

  after do
    FileUtils.remove_entry_secure $wiki_path
    $wiki_path = $wiki_conf.wiki_path
    $wiki_conf.editable = true # "globals #{'rock'.sub(/ro/, 'su')}!"
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

  it 'lockbox encryption key' do
    u = ClWiki::User.new
    u.username = 'foobar'
    u.password = 'my-password'
    key = u.derive_encryption_key('my-password')
    box = Lockbox.new(key: key)
    encrypted_message = box.encrypt('secret message' * 100)

    u = ClWiki::User.new
    u.username = 'foobar'
    u.password = 'my-password'
    key = u.derive_encryption_key('my-password')
    box = Lockbox.new(key: key)
    assert_equal 'secret message' * 100, box.decrypt(encrypted_message)
  end
end
