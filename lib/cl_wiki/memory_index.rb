gem 'clindex'
require 'index'

module ClWiki
  class MemoryIndexer
    attr_reader :index, :pages

    WAIT = true

    def self.instance(page_owner: PublicUser.new)
      @instance ||= self.new(page_owner: page_owner)
    end

    def initialize(page_owner: PublicUser.new)
      @page_owner = page_owner

      @wiki_conf = $wiki_conf
      @root_dir = @wiki_conf.wiki_path

      @index = ClIndex.new
      @recent = ClIndex.new
      @pages = ClIndex.new

      build
    end

    def recent(top = -1, text: '')
      pages_desc_mtime = @recent.do_read(WAIT) do
        hash = @recent.index
        hash.sort { |a, b| b[0] <=> a[0] }
      end.map { |_, page_names| page_names }.flatten

      if text && !text.empty?
        hit_page_names = search(text)
        pages_desc_mtime = pages_desc_mtime & hit_page_names
      end

      pages_desc_mtime[0..top]
    end

    def search(text, titles_only: false)
      terms = text.split(' ')
      all_hits = []
      terms.each do |term|
        term_hits = []
        @index.search(term, term_hits, WAIT)
        term_hits.flatten!
        all_hits = all_hits.empty? ? term_hits : all_hits & term_hits
      end
      all_hits.flatten!
      all_hits.uniq!
      all_hits.sort!
      all_hits.delete_if { |name| !(name =~ /#{text}/i) } if titles_only
      all_hits
    end

    def page_exists?(full_name)
      @pages.term_exists?(full_name, WAIT)
    end

    def reindex_page(page_name)
      remove_page_from_index(page_name)
      index_page(page_name)
    end

    private

    def build
      files = Dir[::File.join(@root_dir, '**/*' + ClWiki::FILE_EXT)]
      files.each do |fn|
        next unless ::File.file?(fn)

        page_name = ::File.basename(fn, ClWiki::FILE_EXT)
        index_page(page_name)
      end
    end

    def index_page(page_name)
      pg = ClWiki::Page.new(page_name, wiki_path: @root_dir, owner: @page_owner)
      pg.read_raw_content
      formatter = ClWiki::PageFormatter.new(pg.raw_content, page_name)
      formatter.format_links { |word| @index.add(word.downcase, page_name, WAIT) }

      add_to_indexes(pg)
    end

    def add_to_indexes(page)
      @index.add(page.page_name, page.page_name, WAIT)
      @pages.add(page.page_name, nil, WAIT)

      @recent.remove(page.page_name, WAIT)
      @recent.add(page.mtime.strftime('%Y-%m-%dT%H:%M:%S'), page.page_name, WAIT)
    end

    def remove_page_from_index(page_name)
      @index.remove(page_name, WAIT)
      @recent.remove(page_name, WAIT)
    end
  end
end
