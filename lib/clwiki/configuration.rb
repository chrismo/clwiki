$defaultConfFile = 'clwiki.conf'

require File.dirname(__FILE__) + '/index'

module ClWiki
  class Configuration

    USE_INDEX_NO = 0
    USE_INDEX_DRB = 1
    USE_INDEX_LOCAL = 2

    attr_accessor :wikiPath, :cgifn, :indexPort, :cssHref, :template, :useGmt,
                  :publishTag, :url_prefix, :global_edits, :cgifn_from_rss, :stats_name,
                  :index_log_fn

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

    def cvs_log
      @cvs_log
    end

    def cvs_log=(value)
      @cvs_log = File.expand_path(value) if value
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

    def enable_cvs
      @enable_cvs
    end

    def enable_cvs=(value)
      if value.class == String
        @enable_cvs = (value =~ /true/i)
      else
        @enable_cvs = value
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

    def initialize
      @cgifn = 'clwikicgi.rb'
      @url_prefix = '/'
      @indexPort = ClWiki::Indexer.defaultPort
      @default_recent_changes_name = "Recent Changes"
      @recent_changes_name = @default_recent_changes_name
      @stats_name = "Hit Counts"
      @useGmt = false
      @publishTag = '<publish>'
      @useIndexForPageExists = false
      @enable_cvs = false
      @showSourceLink = false
      @cgifn_from_rss = 'blogki.rb'
      @edit_rows = 25
      @edit_cols = 80
      @access_log_index = false
      @index_log_fn = nil
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

    def self.scan_conf_lines(confLines, tag)
      confLines.grep(/^#{tag}/).to_s.scan(/^#{tag} (.*)/)
    end

    def self.set_value(item_name, conf_lines)
      value = self.scan_conf_lines(conf_lines, item_name).to_s
      $wikiConf.send(item_name + '=', value) if !value.empty?
    end

    def self.load_xml(fileName=$defaultConfFile)
      if !$wikiConf
        $wikiConf = ClWiki::Configuration.new
        confLines = File.readlines(fileName)

        # refactor this away to just read whatever item names are found in
        # the file
        ClWiki::Configuration.set_value('wikiPath', confLines)
        ClWiki::Configuration.set_value('useIndex', confLines)
        ClWiki::Configuration.set_value('useIndexForPageExists', confLines)
        ClWiki::Configuration.set_value('editable', confLines)
        ClWiki::Configuration.set_value('indexPort', confLines)
        ClWiki::Configuration.set_value('cssHref', confLines)
        ClWiki::Configuration.set_value('template', confLines)
        ClWiki::Configuration.set_value('recentChangesName', confLines)
        ClWiki::Configuration.set_value('publishTag', confLines)
        ClWiki::Configuration.set_value('showSourceLink', confLines)
        ClWiki::Configuration.set_value('cgifn_from_rss', confLines)

        ClWiki::Configuration.set_value('enable_cvs', confLines)
        ClWiki::Configuration.set_value('cvs_log', confLines)

        ClWiki::Configuration.set_value('edit_rows', confLines)
        ClWiki::Configuration.set_value('edit_cols', confLines)

        ClWiki::Configuration.set_value('access_log_index', confLines)

        ClWiki::Configuration.set_value('index_log_fn', confLines)

        $wikiPath = $wikiConf.wikiPath
      end
      $wikiConf
    end
  end
end

if __FILE__ == $0
  ClWiki::Configuration.load_xml
  p $wikiConf
end