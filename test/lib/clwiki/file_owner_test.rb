require_relative 'clwiki_test_helper'
require 'file'

class FileOwnerTest < TestBase
  def test_defaults_to_public_owner
    file = ClWiki::File.new('PublicPage', @test_wiki_path)
    assert file.owner.is_a? ClWiki::PublicUser
  end

  def test_public_owner_cannot_encrypt
    file = ClWiki::File.new('PublicPage', @test_wiki_path)
    assert_raises { file.encrypt_content! }
  end

  def test_real_user_can_encrypt
    user = EncryptingUser.new
    file = ClWiki::File.new('UserPage', @test_wiki_path, owner: user)
    file.encrypt_content!
    file.content = 'My Encrypted Content'

    read_contents = ::File.read(file.full_path_and_name, mode: 'rb')
    refute /Encrypted/.match?(read_contents)

    read_file = ClWiki::File.new('UserPage', @test_wiki_path, owner: user)
    assert_equal 'My Encrypted Content', read_file.content
  end

  def test_different_owner_cannot_read
    foo = EncryptingUser.new('foo')
    bar = EncryptingUser.new('bar')

    file = ClWiki::File.new('FooPage', @test_wiki_path, owner: foo)

    assert_raises do
      ClWiki::File.new('FooPage', @test_wiki_path, owner: bar)
    end
  end

  def test_no_owner_metadata_defaults_to_public
    create_legacy_file('LegacyPage.txt')
    file = ClWiki::File.new('LegacyPage', @test_wiki_path)
    assert_equal 'public', file.owner.name
  end

  def test_no_owner_metadata_but_encrypted_raises
    # if there is no owner, BUT file is set to encrypt -
    # well ... this would fail naturally ... right?
  end

  def test_public_page_not_encrypted_accessible_by_anyone
    create_legacy_file('LegacyPage.txt')
    user = EncryptingUser.new

    file = ClWiki::File.new('LegacyPage', @test_wiki_path, owner: user)
    assert_equal user.name, file.owner.name
  end
end
