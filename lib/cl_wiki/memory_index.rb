module ClWiki
  class MemoryIndexer
    attr_reader :index, :pages

    WAIT = true

    def initialize(wiki_conf = $wiki_conf)
      @wiki_conf = wiki_conf
      @root_dir = @wiki_conf.wiki_path

      @index = ClIndex.new
      @recent = ClIndex.new
      @pages = ClIndex.new

      build
    end

    def recent
      @recent.do_read(WAIT) do
        hash = @recent.index
        hash.sort { |a, b| b[0] <=> a[0] }
      end
    end

    def search(text)
      terms = text.split(' ')
      all_hits = nil
      terms.each do |term|
        term_hits = []
        @index.search(term, term_hits, WAIT)
        term_hits.flatten!
        all_hits = !all_hits ? term_hits : all_hits & term_hits
      end
      all_hits.flatten!
      all_hits.uniq!
      all_hits.sort!
      all_hits
    end

    def page_exists?(full_name)
      @pages.term_exists?(full_name, WAIT)
    end

    private

    def build
      # TODO: change to use FindInFile
      files = Dir[::File.join(@root_dir, '**/*' + ClWiki::FILE_EXT)]
      files.each do |fn|
        next unless ::File.file?(fn)

        full_name = fn.sub(@root_dir, '')
        full_name = full_name.sub(/#{ClWiki::FILE_EXT}/, '')
        index_page(full_name)
      end
    end

    def index_page(full_name)
      # TODO: Page needs owner
      pg = ClWiki::Page.new(full_name, wiki_path: @root_dir)
      pg.read_raw_content
      formatter = ClWiki::PageFormatter.new(pg.raw_content, full_name)
      formatter.format_links { |word| @index.add(word.downcase, full_name, WAIT) }

      add_to_indexes(pg)
    end

    def add_to_indexes(page)
      @index.add(page.full_name, page.full_name, WAIT)
      @pages.add(page.full_name, nil, WAIT)

      @recent.remove(page.full_name, WAIT)
      @recent.add(page.mtime.strftime('%Y-%m-%dT%H:%M:%S'), page.full_name, WAIT)
    end
  end
end