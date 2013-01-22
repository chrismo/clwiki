class PageFixture
  def self.write_page(name, contents)
    @page = ClWiki::Page.new("#{name[0..0] != '/' ? '/' : ''}#{name}")
    @page.update_content(contents, @page.mtime)
    $wiki_conf.wait_on_threads
  end
end
