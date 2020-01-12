# frozen_string_literal: true

require 'yaml'

$defaultConfFile = 'clwiki.yml'

module ClWiki
  #noinspection RubyTooManyInstanceVariablesInspection
  class Configuration
    attr_accessor :wiki_path, :cssHref, :template, :publishTag, :url_prefix,
                  :global_edits, :page_update_format, :use_authentication,
                  :owner, :encryption_default
    attr_reader   :custom_formatter_load_path

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

    def show_source_link
      @show_source_link
    end

    def show_source_link=(value)
      if value.class == String
        @show_source_link = (value =~ /true/i)
      else
        @show_source_link = value
      end
    end

    def self.load(filename=$defaultConfFile)
      $wiki_conf = self.new(YAML::load(::File.open(filename)))
    end

    def initialize(hash={})
      default_hash.merge(hash).each do |k, v|
        instance_variable_set(:"@#{k.to_s}", v)
      end
    end

    def default_hash
      {
        url_prefix: '/',
        default_recent_changes_name: 'Recent Changes',
        recent_changes_name: 'Recent Changes',
        publishTag: nil,
        useIndexForPageExists: false,
        show_source_link: false,
        edit_rows: 25,
        edit_cols: 80,
        access_log_index: false,
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

    def recent_changes_name=(value)
      @recent_changes_name = value
      @recent_changes_name = @default_recent_changes_name if @recent_changes_name.empty?
    end

    def recent_changes_name
      @recent_changes_name
    end
  end
end
