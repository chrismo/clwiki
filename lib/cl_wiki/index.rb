require 'rubygems'

require File.expand_path('page', __dir__)
require File.expand_path('configuration', __dir__)
require File.expand_path('memory_index', __dir__)
require 'cl/util/progress'
require 'cl/util/console'

gem 'clindex'
require 'index'

require 'drb'

module ClWiki
  class Indexer
    attr_reader :index

    WAIT = true

    def self.defaultPort
      '9111'
    end

    def initialize(wiki_conf=$wiki_conf, fn=nil)
      @wiki_conf = wiki_conf

      @index = ClIndex.new
      @recent = ClIndex.new
      @pages = ClIndex.new
      @hits = ClIndex.new if @wiki_conf.access_log_index
      @rootDir = @wiki_conf.wiki_path
      @fn = fn
      @record_hits = true
      load
    end

    def do_puts(text)
      if @fn
        ::File.open(@fn, 'a+') do |f|
          f.puts text
        end
      else
        puts text
      end
    end

    def build(limit=-1, purge=false)
      @record_hits = false
      begin
        fileCount = 0
        files = Dir[::File.join(@rootDir, '**/*' + ClWiki::FILE_EXT)]
        if limit == -1
          p = Progress.new(files.length)
        else
          p = Progress.new(limit)
        end
        p.start
        files.each do |fn|
          next if !::File.file?(fn)
          break if (limit > -1) && (fileCount >= limit)
          fileCount += 1
          fullName = fn.sub(@rootDir, '')
          fullName = fullName.sub(/#{ClWiki::FILE_EXT}/, '')
          index_page(fullName, purge)
          do_puts p.progress(true)
        end
      ensure
        @record_hits = true
      end
    end

    def index_page(fullName, purge=false)
      put_status "indexing #{fullName}" do
        # TODO: Page needs owner
        pg = ClWiki::Page.new(fullName, wiki_path: @rootDir)
        pg.read_raw_content
        # TODO: move purging these pages to its own script
        if purge && pg.content_never_edited?
          put_status("purging #{fullName}")
          pg.delete
          remove_page_from_index(fullName)
        else
          formatter = ClWiki::PageFormatter.new(pg.raw_content, fullName)
          formatter.format_links do |word|
            add_to_index(word.downcase, fullName)
          end
          add_to_index(fullName, fullName)
          add_to_pages(fullName)

          add_to_recent(pg.mtime, fullName)
        end
      end
    end

    def add_to_index(term, fullPageName)
      @index.add(term, fullPageName, WAIT)
    end

    def add_to_recent(modTime, fullPageName)
      # remove all other instances of this page, we only need the current modTime
      @recent.remove(fullPageName, WAIT)
      @recent.add(modTime.strftime("%Y-%m-%dT%H:%M:%S"), fullPageName, WAIT)
    end

    def add_to_pages(fullPageName)
      @pages.add(fullPageName, nil, WAIT)
    end

    def hits_filename
      ::File.join(::File.expand_path($wiki_path), 'hits.dat')
    end

    def index_filename
      ::File.join(::File.expand_path($wiki_path), 'index.dat')
    end

    def recent_filename
      ::File.join(::File.expand_path($wiki_path), 'recent.dat')
    end

    def pages_filename
      ::File.join(::File.expand_path($wiki_path), 'pages.dat')
    end

    def remove_page_from_index(fullPageName)
      @index.remove(fullPageName, WAIT)
      @recent.remove(fullPageName, WAIT)
    end

    def put_status(status)
      if block_given?
        do_puts Time.now.strftime("%I:%M:%S") + ' ' + status + '... '
        yield
        do_puts Time.now.strftime("%I:%M:%S") + ' ' + status + ' done '
      else
        do_puts Time.now.strftime("%I:%M:%S") + ' ' + status
      end
    end

    def reindex_and_save_async(fullPageName)
      thread = Thread.new do
        reindex_page(fullPageName)
        save
      end
      @wiki_conf.wait_on_thread(thread)
    end

    def reindex_page(fullPageName)
      put_status 'Reindexing ' + fullPageName do
        remove_page_from_index(fullPageName)
        index_page(fullPageName)
      end
    end

    def save
      put_status 'Saving' do
        put_status 'Saving Main' do
          @index.save(index_filename, WAIT)
        end
        put_status 'Saving Recent' do
          @recent.save(recent_filename, WAIT)
        end
        put_status 'Saving Pages' do
          @pages.save(pages_filename, WAIT)
        end
        put_status 'Saving Hits' do
          @hits.save(hits_filename, WAIT) if @wiki_conf.access_log_index
        end
      end
    end

    def load
      put_status 'Loading' do
        put_status 'Loading Main' do
          @index.load(index_filename, WAIT) if ::File.exist?(index_filename)
        end
        put_status 'Loading Recent' do
          @recent.load(recent_filename, WAIT) if ::File.exist?(recent_filename)
        end
        put_status 'Loading Pages' do
          @pages.load(pages_filename, WAIT) if ::File.exist?(pages_filename)
        end
        if @wiki_conf.access_log_index
          put_status 'Loading Hits' do
            @hits.load(hits_filename, WAIT) if ::File.exist?(hits_filename)
          end
        end
      end
    end

    def dump_clindex(aindex, fn_prefix)
      put_status "Dumping #{fn_prefix}..." do
        hash = aindex.index
        ::File.open(fn_prefix + '.keys.dump.txt', 'w+') do |f|
          keys = hash.keys
          keys.sort.each do |key|
            f.puts key
          end
        end
        File.open(fn_prefix + '.full.dump.txt', 'w+') do |f|
          fullary = hash.to_a
          fullary.sort!
          fullary.each do |keyValueAry|
            f.puts keyValueAry[0].inspect + " => " + keyValueAry[1].inspect
          end
        end
      end
    end

    def dump
      dump_clindex(@index, 'index')
      dump_clindex(@recent, 'recent')
      dump_clindex(@pages, 'pages')
      dump_clindex(@hits, 'hits') if @wiki_conf.access_log_index
    end

    def search(text)
      terms = text.split(' ')
      allhits = nil
      terms.each do |term|
        termhits = []
        @index.search(term, termhits, WAIT)
        termhits.flatten!
        if !allhits
          allhits = termhits
        else
          allhits = allhits & termhits
        end
      end
      allhits = [] if !allhits # shouldn't ever happen I'd wager
      p allhits if $debug
      allhits.flatten!
      allhits.uniq!
      allhits.sort!
      p allhits if $debug
      allhits
    end

    def sort_hits_by_recent(hits, top=-1)
      hits_by_date = {}
      # don't send top into this call to recent, we need all recent, then
      # we filter that down to all matches, /then/ we take the topmost
      # of that matching list
      recent.each do |date, page_name_array|
        hits_at_this_time = page_name_array & hits
        hits_by_date[date] = hits_at_this_time if !hits_at_this_time.empty?
      end
      hits_by_date.sort { |a, b| b[0] <=> a[0] }[0..top]
    end

    def recent(top=-1)
      @recent.do_read(WAIT) do
        hash = @recent.index
        hash.sort { |a, b| b[0] <=> a[0] }[0..top]
      end
    end

    # TODO: remove this method out to dot script.
    def pages_out(rootPage)
      all = @index.all_terms(rootPage, WAIT)
      #all.delete_if do |term|
      #  term[0..0] != '/' || !ClWikiPage.page_exists?(term.dup)
      #end
      all.delete_if do |term|
        (term[0..0] != '/') || (term == '/') || (term == '//')
      end
      all.delete_if do |term|
        !ClWikiPage.page_exists?(term.dup)
      end
      all
    end

    def page_exists?(fullPageName)
      @pages.term_exists?(fullPageName, WAIT)
    end

    def add_hit(fullPageName)
      if @record_hits && @wiki_conf.access_log_index
        put_status('Hit on ' + fullPageName)
        @hits.add(fullPageName, Time.now, WAIT)
        thread = Thread.new do
          @hits.save(hits_filename, WAIT)
        end
        @wiki_conf.wait_on_thread(thread)
      end
    end

    def hit_summary(start_index=0, end_index=-1)
      if @wiki_conf.access_log_index
        hit_index = nil
        @hits.do_read(WAIT) do
          hit_index = @hits.index.dup
        end
        hit_index.sort { |a, b| b[1].length <=> a[1].length }[start_index..end_index]
      end
    end
  end

  class IndexClient
    def initialize(wiki_conf = $wiki_conf)
      case wiki_conf.useIndex
      when ClWiki::Configuration::USE_INDEX_NO
        raise 'wikiConf.useIndex says to not use an index'
      when ClWiki::Configuration::USE_INDEX_DRB
        DRb.start_service()
        @indexer = DRbObject.new(nil, "druby://localhost:#{wiki_conf.indexPort}")
      when ClWiki::Configuration::USE_INDEX_LOCAL
        $indexer ||= ClWiki::Indexer.new(wiki_conf, wiki_conf.index_log_fn)
        @indexer = $indexer
      when ClWiki::Configuration::USE_INDEX_MEMORY
        $indexer ||= ClWiki::MemoryIndexer.new(wiki_conf)
        @indexer = $indexer
      end
    end

    def reindex_page_and_save_async(fullPageName)
      @indexer.reindex_and_save_async(fullPageName)
    end

    def reindex_page(full_page_name)
      @indexer.reindex_page(full_page_name)
    end

    def save
      @indexer.save
    end

    def search(term, titles_only=false)
      hits = @indexer.search(term).flatten
      if titles_only
        hits.delete_if do |fullName|
          !(fullName =~ /#{term}/i)
        end
      end
      hits
    end

    def page_exists?(fullPageName)
      @indexer.page_exists?(fullPageName)
    end

    def sort_hits_by_recent(hits, top=-1)
      @indexer.sort_hits_by_recent(hits, top)
    end

    def recent(top=-1)
      @indexer.recent(top)
    end

    def add_hit(fullPageName)
      @indexer.add_hit(fullPageName)
    end

    def hit_summary(start_index=0, end_index=-1)
      @indexer.hit_summary(start_index, end_index)
    end
  end
end


def launch_server(port=nil, fn=nil)
  port = ClWiki::Indexer.defaultPort if !port
  idxServer = ClWiki::Indexer.new(fn)
  puts "ClWikiIndexer launching on localhost:#{port}..."
  DRb.start_service("druby://localhost:#{port}", idxServer)
  DRb.thread.join
end

if __FILE__ == $0
  def do_page_exists(fullPageName)
    if @i.page_exists?(fullPageName)
      puts fullPageName + ' exists'
    else
      puts fullPageName + ' does not exist'
    end
  end

  def do_search(search)
    puts @i.search(search).join("\n")
    puts
  end

  def do_index_dump
    puts 'Dumping...'
    @i.dump
  end

  def do_recent
    puts @i.recent
    puts
  end

  def do_hits
    puts @i.hit_summary.inspect
    puts
  end

  def show_help
    puts 'ClWikiIndexer'
    puts
    puts '-h        Show this help'
    puts
    puts '-s        Launch drb server'
    puts "-p        Drb port. Default is #{ClWiki::Indexer.defaultPort}"
    puts '-f [fn]   File to route output to. stdout used if not specified'
    puts '-b        Do a full re-build of the index'
    puts '-bp       Do a full re-build, purging unused pages. An unused page'
    puts '          is one where the contents are the default content after'
    puts '          creation, but has never been edited.'
    puts '-l [x]    If -b, limit number of pages built to x'
    puts '<none>    load index to search for terms entered in stdin'
    puts '-q [term] load index and search for term'
    puts '-r [page] load index and see if page exists'
    puts '-x [page] load index and re-index the specified page'
    puts '-d        debug'
    puts '-dump     dumps full index to text file'
    puts '-recent   show 1st recent hits'
    puts '-hits     show 1st hit count'
  end

  $debug = if_switch('-d')

  if if_switch('-h')
    show_help
  elsif if_switch('-s')
    launch_server(get_switch('-p'), get_switch('-f'))
  elsif if_switch('-b') || if_switch('-bp')
    limit = -1
    limit = get_switch('-l').to_i if get_switch('-l')
    @i = ClWiki::Indexer.new
    $wiki_conf.access_log_index = false
    @i.build(limit, if_switch('-bp'))
    @i.save
  else
    puts 'loading index...'
    @i = ClWiki::Indexer.new
    $wiki_conf.access_log_index = false
    #@i.load
    if get_switch('-q')
      do_search(get_switch('-q'))
    elsif if_switch('-recent')
      do_recent
    elsif if_switch('-hits')
      do_hits
    elsif get_switch('-r')
      do_page_exists(get_switch('-r'))
    elsif if_switch('-dump')
      do_index_dump
    elsif if_switch('-x')
      @i.index_page(get_switch('-x'))
      @i.save
    else
      begin
        print 'input search term (empty to quit): '
        search = gets.chomp
        break if search.empty?
        do_search(search)
      end while true
    end
  end
end

