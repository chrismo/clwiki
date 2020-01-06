class PageFixture
  def self.write_page(name, contents, owner:)
    @page = ClWiki::Page.new(name.ensure_slash_prefix, owner: owner)
    @page.update_content(contents, @page.mtime)
    $wiki_conf.wait_on_threads
  end
end

class AuthFixture
  def self.create_test_user
    ClWiki::User.create('testy', 'red pill')
  end
end
