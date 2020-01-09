class PageFixture
  def self.write_page(name, contents, owner:)
    @page = ClWiki::Page.new(name, owner: owner)
    @page.update_content(contents, @page.mtime)
  end
end

class AuthFixture
  def self.create_test_user
    ClWiki::User.create('testy', 'red pill')
  end
end
