# frozen_string_literal: true

require File.expand_path('index', __dir__)
require 'yaml'

$defaultConfFile = 'clwiki.yml'

module ClWiki
  class Configuration

    USE_INDEX_NO = 0
    USE_INDEX_DRB = 1
    USE_INDEX_LOCAL = 2
    USE_INDEX_MEMORY = 3

    attr_accessor :wiki_path, :cgifn, :indexPort, :cssHref, :template, :useGmt,
                  :publishTag, :url_prefix, :global_edits, :cgifn_from_rss, :stats_name,
                  :index_log_fn, :page_update_format, :use_authentication
    attr_reader   :custom_formatter_load_path

    def wait_on_threads
      # Ruby kills any threads as soon as the main process is done. Any
      # threads created should be registered here. The last
      # line of the CGI script should call out to wait_on_threads to make
      # sure nothing running async in the background is terminated too early
      @threads.each do |thread|
        thread.join
      end if !@threads.nil?
    end

    def wait_on_thread(thread)
      @threads = [] if !@threads
      @threads << thread
    end

    def useIndex
      @useIndex
    end

    def useIndex=(value)
      @useIndex = value.to_i
    end

    def edit_rows
      @edit_rows
    end

    def edit_rows=(value)
      @edit_rows = value.to_i
    end

    def edit_cols
      @edit_cols
    end

    def edit_cols=(value)
      @edit_cols = value.to_i
    end

    def useIndexForPageExists
      @useIndexForPageExists
    end

    def useIndexForPageExists=(value)
      if value.class == String
        @useIndexForPageExists = (value =~ /true/i)
      else
        @useIndexForPageExists = value
      end
    end

    def access_log_index
      @access_log_index
    end

    def access_log_index=(value)
      if value.class == String
        @access_log_index = (value =~ /true/i)
      else
        @access_log_index = value
      end
    end

    def override_access_log_index
      @orig_access_log_index_value = @access_log_index
      @access_log_index = false
    end

    def restore_access_log_index
      @access_log_index = @orig_access_log_index_value if @orig_access_log_index_value
    end

    def editable
      @editable
    end

    def editable=(value)
      if value.class == String
        @editable = (value =~ /true/i)
      else
        @editable = value
      end
    end

    def showSourceLink
      @showSourceLink
    end

    def showSourceLink=(value)
      if value.class == String
        @showSourceLink = (value =~ /true/i)
      else
        @showSourceLink = value
      end
    end

    def self.load(filename=$defaultConfFile)
      $wiki_conf = self.new(YAML::load(::File.open(filename)))
      $wiki_path = $wiki_conf.wiki_path
      $wiki_conf
    end

    def initialize(hash={})
      default_hash.merge(hash).each do |k, v|
        instance_variable_set(:"@#{k.to_s}", v)
      end
    end

    def default_hash
      {
        url_prefix: '/',
        indexPort: ClWiki::Indexer.defaultPort,
        cgifn: 'clwikicgi.rb',
        default_recent_changes_name: 'Recent Changes',
        recent_changes_name: 'Recent Changes',
        stats_name: 'Hit Counts',
        useGmt: false,
        publishTag: nil,
        useIndexForPageExists: false,
        showSourceLink: false,
        cgifn_from_rss: 'blogki.rb',
        edit_rows: 25,
        edit_cols: 80,
        access_log_index: false,
        index_log_fn: nil,
        custom_formatter_load_path: [],
        use_authentication: false
      }
    end

    def default_recent_changes_name=(value)
      if @recent_changes_name == @default_recent_changes_name
        @recent_changes_name = value
      end
      @default_recent_changes_name = default_recent_changes_name
    end

    def default_recent_changes_name
      @default_recent_changes_name
    end

    def recentChangesName=(value)
      @recent_changes_name = value
      @recent_changes_name = @default_recent_changes_name if @recent_changes_name.empty?
    end

    alias recent_changes_name= recentChangesName=

    def recentChangesName
      @recent_changes_name
    end

    alias recent_changes_name recentChangesName
  end
end
