require 'fileutils'
require 'time'

require 'lockbox'

require File.expand_path('page', __dir__)


module ClWiki
  FILE_EXT = '.txt'

  class File
    attr_reader :name, :wikiRootPath, :pagePath, :mod_time_at_last_read, :metadata
    attr_accessor :clientLastReadModTime

    def initialize(fullPageName, wikiRootPath, auto_create: true)
      @wikiRootPath = wikiRootPath
      fullPageName = ClWiki::Util.convertToNativePath(fullPageName)
      fullPageName.ensure_slash_prefix
      @pagePath, @name = ::File.split(fullPageName)
      @pagePath = '/' if @pagePath == '.'
      @metadata = {}
      @metadata_keys = %w[mtime encrypted]
      if auto_create
        if file_exists?
          readFile
        else
          writeToFile(default_content, false)
        end
      end
    end

    # TODO: consider removing
    def content_is_default?
      @contents.to_s == default_content
    end

    def delete
      File.delete(fullPathAndName) if File.exists?(fullPathAndName)
    end

    def default_content
      "Describe " + @name + " here."
    end

    def file_exists?
      FileTest.exist?(fullPathAndName)
    end

    # TODO: make private and/or remove outright.
    def fullPath
      res = ::File.expand_path(::File.join(@wikiRootPath, @pagePath))
      raise 'no dirs in fullPath' if res.split('/').empty?
      res
    end

    def fullPathAndName
      ::File.expand_path(@name + FILE_EXT, fullPath)
    end

    def fileName
      raise Exception, 'ClWikiFile.fileName is deprecated, use fullPathAndName'
      # fullPathAndName
    end

    def content
      @contents
    end

    def content=(newContent)
      writeToFile(newContent)
    end

    def writeToFile(content, check_mod_time = true)
      if check_mod_time
        # refactor, bring raiseIfMTimeNotEqual back into this class
        ClWiki::Util.raiseIfMTimeNotEqual(@mod_time_at_last_read, fullPathAndName)
        unless @clientLastReadModTime.nil?
          ClWiki::Util.raiseIfMTimeNotEqual(@clientLastReadModTime, fullPathAndName)
        end
      end

      make_dirs(fullPath)
      ding_mtime
      file_contents = ''.tap do |s|
        s << metadata_to_write
        s << (content_encrypted? ? lock_box.encrypt(content) : content)
      end
      ::File.binwrite(fullPathAndName, file_contents)
      ::File.utime(@metadata['mtime'], @metadata['mtime'], fullPathAndName)
      readFile
    end

    def ding_mtime
      @metadata['mtime'] = Time.now
    end

    def metadata_to_write
      @metadata.collect { |k, v| "#{k}: #{v}" }.join("\n") + "\n\n\n"
    end

    # TODO: remove, we don't support full hierarchy anymore.
    def make_dirs(dir)
      # need to commit each dir as we make it, which is why we just don't
      # call File::makedirs. Core code copied from ftools.rb
      parent = ::File.dirname(dir)
      return if parent == dir or FileTest.directory? dir
      make_dirs parent unless FileTest.directory? parent
      if ::File.basename(dir) != ""
        Dir.mkdir dir, 0755
      end
    end

    def readFile
      @mod_time_at_last_read = ::File.mtime(fullPathAndName)

      # positive lookbehind regex is used here to retain the end of line
      # newline, because this used to just be `File.readlines` which also keeps
      # the newline characters.
      raw_lines = ::File.binread(fullPathAndName).split(/(?<=\n)/)

      metadata_lines, raw_content = split_metadata(raw_lines)
      read_metadata(metadata_lines)
      apply_metadata

      if content_encrypted?
        decrypted_content = lock_box.decrypt_str(raw_content.join)
        @contents = decrypted_content
      else
        @contents = raw_content
      end
    end

    # TODO: this implementation seems quite tortured
    # TODO: metadata should go into its own class
    def split_metadata(raw_lines)
      start_index = 0
      raw_lines.each_with_index do |ln, index|
        if ln.chomp.empty?
          next_line = raw_lines[index+1]
          if next_line.nil? || next_line.chomp.empty?
            if all_lines_are_metadata_lines(raw_lines[0..index-1])
              start_index = index + 2
            end
            break
          end
        end
      end

      if start_index > 0
        [raw_lines[0..start_index-3], raw_lines[start_index..-1]]
      else
        [[], raw_lines]
      end
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

    private

    def lock_box
      Lockbox.new(key: '0' * 64)
    end
  end

  class Util
    def self.raiseIfMTimeNotEqual(mtime_to_compare, file_name)
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

    def self.convertToNativePath(path)
      newpath = path.gsub(/\//, ::File::SEPARATOR)
      newpath = newpath.gsub(/\\/, ::File::SEPARATOR)
      return newpath
    end
  end

  class FileError < Exception
  end

  class FileModifiedSinceRead < FileError
  end
end
