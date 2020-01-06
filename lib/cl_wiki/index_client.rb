require 'rubygems'

require File.expand_path('page', __dir__)
require File.expand_path('configuration', __dir__)
require File.expand_path('memory_index', __dir__)
require 'cl/util/progress'
require 'cl/util/console'

gem 'clindex'
require 'index'

module ClWiki
  # TODO: Without any additional index types, is this class necessary?
  class IndexClient
    def initialize(page_owner: PublicUser.new)
      $indexer ||= ClWiki::MemoryIndexer.new(page_owner: page_owner)
      @indexer = $indexer
    end

    def reindex_page_and_save_async(full_page_name)
      @indexer.reindex_and_save_async(full_page_name)
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

    def sort_hits_by_recent(hits, top = -1)
      @indexer.sort_hits_by_recent(hits, top)
    end

    def recent(top = -1, text: '')
      @indexer.recent(top, text: text)
    end
  end
end
