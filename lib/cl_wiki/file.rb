# frozen_string_literal: true

require 'fileutils'
require 'time'

module ClWiki
  class File
    FILE_EXT = '.txt'

    attr_reader :name, :mod_time_at_last_read, :metadata, :owner
    attr_accessor :client_last_read_mod_time

    def initialize(page_name, wiki_root_path, auto_create: true, owner: PublicUser.new)
      @wiki_root_path = wiki_root_path
      @owner = owner
      @name = ::File.basename(ClWiki::Util.convert_to_native_path(page_name))
      @metadata = Metadata.new
      if auto_create
        file_exists? ? read_file : write_to_file(default_content, false)
      end
    end

    def has_default_content?
      @contents.to_s == default_content
    end

    def default_content
      "Describe #{@name} here."
    end

    def delete
      ::File.delete(full_path_and_name) if file_exists?
    end

    def file_exists?
      FileTest.exist?(full_path_and_name)
    end

    def full_path_and_name
      ::File.expand_path(@name + FILE_EXT, @wiki_root_path)
    end

    def content
      @contents
    end

    def content=(new_content)
      write_to_file(new_content)
    end

    def write_to_file(content, check_mod_time = true)
      do_mod_time_check if check_mod_time

      update_metadata
      file_contents = String.new.tap do |s|
        s << @metadata.to_s
        s << (content_encrypted? ? @owner.lockbox.encrypt(content) : content)
      end
      ::File.binwrite(full_path_and_name, file_contents)
      ::File.utime(@metadata['mtime'], @metadata['mtime'], full_path_and_name)
      read_file
    end

    def read_file
      @mod_time_at_last_read = ::File.mtime(full_path_and_name)

      raw_bytes = ::File.binread(full_path_and_name)
      @metadata, raw_content = Metadata.split_file_contents(raw_bytes)

      apply_metadata

      @contents = if content_encrypted?
                    @owner.lockbox.decrypt_str(raw_content)
                  else
                    raw_content.force_encoding('UTF-8')
                  end
    end

    def read_metadata(lines)
      @metadata = Metadata.new(lines)
    end

    def apply_metadata
      @mod_time_at_last_read = Time.parse(@metadata['mtime']) if @metadata.has? 'mtime'
      ensure_same_owner!
    end

    def content_encrypted?
      @metadata['encrypted'] == 'true'
    end

    def encrypt_content!
      raise "Owner <#{@owner.name}> cannot encrypt" unless @owner.can_encrypt?

      @metadata['encrypted'] = 'true'
    end

    def do_not_encrypt_content!
      @metadata['encrypted'] = 'false'
    end

    private

    def do_mod_time_check
      ClWiki::Util.raise_if_mtime_not_equal(@mod_time_at_last_read, full_path_and_name)
      unless @client_last_read_mod_time.nil?
        ClWiki::Util.raise_if_mtime_not_equal(@client_last_read_mod_time, full_path_and_name)
      end
    end

    def update_metadata
      @metadata['mtime'] = Time.now
      @metadata['owner'] = @owner.name
    end

    def ensure_same_owner!
      meta_owner = @metadata['owner']
      is_legacy_file = meta_owner.to_s.empty?
      unless is_legacy_file || meta_owner == @owner.name
        raise "Owner must match: <#{meta_owner}> - <#{@owner.name}>"
      end
    end
  end
end
