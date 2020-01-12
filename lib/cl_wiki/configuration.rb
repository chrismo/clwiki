# frozen_string_literal: true

require 'yaml'

$defaultConfFile = 'clwiki.yml'

module ClWiki
  # noinspection RubyTooManyInstanceVariablesInspection
  class Configuration
    attr_accessor :wiki_path, :cssHref, :template, :publishTag, :url_prefix,
                  :global_edits, :page_update_format, :use_authentication,
                  :owner, :encryption_default
    attr_reader   :custom_formatter_load_path

    def initialize(hash = {})
      default_hash.merge(hash).each do |k, v|
        instance_variable_set(:"@#{k.to_s}", v)
      end
    end

    def default_hash
      {
        url_prefix: '/',
        publishTag: nil,
        useIndexForPageExists: false,
        edit_rows: 25,
        edit_cols: 80,
        access_log_index: false,
        custom_formatter_load_path: [],
        use_authentication: false
      }
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

    def self.load(filename = $defaultConfFile)
      $wiki_conf = self.new(YAML::load(::File.open(filename)))
    end
  end
end
