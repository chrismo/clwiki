require 'fileutils'
require 'time'

require 'lockbox'

require File.expand_path('page', __dir__)


module ClWiki
  FILE_EXT = '.txt'

  class File
    attr_reader :name, :mod_time_at_last_read, :metadata
    attr_accessor :client_last_read_mod_time

    def initialize(full_page_name, wiki_root_path, auto_create: true)
      @wiki_root_path = wiki_root_path
      full_page_name = ClWiki::Util.convert_to_native_path(full_page_name).ensure_slash_prefix
      _, @name = ::File.split(full_page_name)
      @metadata = {}
      @metadata_keys = %w[mtime encrypted]
      if auto_create
        file_exists? ? read_file : write_to_file(default_content, false)
      end
    end

    # TODO: consider removing
    def content_is_default?
      @contents.to_s == default_content
    end

    def delete
      ::File.delete(full_path_and_name) if file_exists?
    end

    def default_content
      "Describe " + @name + " here."
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
      if check_mod_time
        # refactor, bring raise_if_mtime_not_equal back into this class
        ClWiki::Util.raise_if_mtime_not_equal(@mod_time_at_last_read, full_path_and_name)
        unless @client_last_read_mod_time.nil?
          ClWiki::Util.raise_if_mtime_not_equal(@client_last_read_mod_time, full_path_and_name)
        end
      end

      ding_mtime
      file_contents = ''.tap do |s|
        s << metadata_to_write
        s << (content_encrypted? ? lock_box.encrypt(content) : content)
      end
      ::File.binwrite(full_path_and_name, file_contents)
      ::File.utime(@metadata['mtime'], @metadata['mtime'], full_path_and_name)
      read_file
    end

    def ding_mtime
      @metadata['mtime'] = Time.now
    end

    def metadata_to_write
      @metadata.collect { |k, v| "#{k}: #{v}" }.join("\n") + "\n\n\n"
    end

    def read_file
      @mod_time_at_last_read = ::File.mtime(full_path_and_name)

      # positive lookbehind regex is used here to retain the end of line
      # newline, because this used to just be `File.readlines` which also keeps
      # the newline characters.
      raw_lines = ::File.binread(full_path_and_name).split(/(?<=\n)/)

      metadata_lines, raw_content = split_metadata(raw_lines)
      read_metadata(metadata_lines)
      apply_metadata

      content_encrypted? ? @contents = lock_box.decrypt_str(raw_content.join) : @contents = raw_content
    end

    # TODO: this implementation seems quite tortured
    # TODO: metadata should go into its own class
    def split_metadata(raw_lines)
      st_idx = 0
      raw_lines.each_with_index do |ln, index|
        if ln.chomp.empty?
          next_line = raw_lines[index+1]
          if next_line.nil? || next_line.chomp.empty?
            st_idx = index + 2 if all_lines_are_metadata_lines(raw_lines[0..index-1])
            break
          end
        end
      end

      (st_idx > 0) ? [raw_lines[0..st_idx - 3], raw_lines[st_idx..-1]] : [[], raw_lines]
    end

    def all_lines_are_metadata_lines(lines)
      lines.map { |ln| ln.scan(/\A(\w+):?/) }.flatten.
        map { |k| @metadata_keys.include?(k) }.uniq == [true]
    end

    def read_metadata(lines)
      @metadata = {}
      lines.each do |ln|
        key, value = ln.split(': ')
        @metadata[key] = value.chomp if @metadata_keys.include?(key)
      end
    end

    # rubocop:disable Rails/TimeZone
    def apply_metadata
      @mod_time_at_last_read = Time.parse(@metadata['mtime']) if @metadata.key? 'mtime'
    end
    # rubocop:enable Rails/TimeZone

    def content_encrypted?
      @metadata['encrypted'] == 'true'
    end

    def encrypt_content!
      @metadata['encrypted'] = 'true'
    end

    def lock_box
      Lockbox.new(key: '0' * 64)
    end
  end

  class Util
    def self.raise_if_mtime_not_equal(mtime_to_compare, file_name)
      # reading the instance .mtime appears to take Windows DST into account,
      # whereas the static File.mtime(filename) method does not
      current_mtime = ::File.open(file_name) do |f|
        f.mtime
      end
      compare_read_times!(mtime_to_compare, current_mtime)
    end

    def self.compare_read_times!(a, b)
      # ignore usec
      a = Time.new(a.year, a.month, a.day, a.hour, a.min, a.sec)
      b = Time.new(b.year, b.month, b.day, b.hour, b.min, b.sec)
      if a != b
        raise FileModifiedSinceRead, "File has been modified since it was last read. #{dump_time(a)} != #{dump_time(b)}"
      end
    end

    def self.dump_time(time)
      ''.tap do |s|
        s << "#{time}"
        s << ".#{time.usec}" if time.respond_to?(:usec)
      end
    end

    def self.convert_to_native_path(path)
      path.gsub(/\//, ::File::SEPARATOR).gsub(/\\/, ::File::SEPARATOR)
    end
  end

  class FileError < Exception
  end

  class FileModifiedSinceRead < FileError
  end
end
