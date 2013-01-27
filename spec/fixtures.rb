class PageFixture
  def self.write_page(name, contents)
    @page = ClWiki::Page.new(name.ensure_slash_prefix)
    @page.update_content(contents, @page.mtime)
    $wiki_conf.wait_on_threads
  end
end
