# frozen_string_literal: true
class PageFixture
  def self.write_page(name, contents, owner:)
    @page = ClWiki::Page.new(name, owner: owner)
    @page.update_content(contents, @page.mtime)
  end
end

class AuthFixture
  def self.create_test_user
    ClWiki::User.create('testy', 'red pill').tap do |u|
      key = u.derive_encryption_key('red pill')
      u.cached_encryption_key = key
    end
  end
end
