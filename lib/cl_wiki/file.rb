require 'fileutils'
require 'time'

require_relative 'page'

$wikiPageExt = '.txt'

module ClWiki
  class File
    attr_reader :name, :fileExt, :wikiRootPath, :pagePath, :modTimeAtLastRead
    attr_accessor :clientLastReadModTime

    def initialize(fullPageName, wikiRootPath, fileExt=$wikiPageExt, autocreate=true)
      # fullPageName must start with / ?
      @wikiRootPath = wikiRootPath
      fullPageName = ClWiki::Util.convertToNativePath(fullPageName)
      fullPageName.ensure_slash_prefix
      @pagePath, @name = ::File.split(fullPageName)
      @pagePath = '/' if @pagePath == '.'
      @fileExt = fileExt
      @metadata = {}
      if autocreate
        if file_exists?
          readFile
        else
          writeToFile(default_content, false)
        end
      end
    end

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
      FileTest.exists?(fullPathAndName)
    end

    def fullPath
      res = ::File.expand_path(::File.join(@wikiRootPath, @pagePath))
      raise 'no dirs in fullPath' if res.split('/').empty?
      res
    end

    def fullPathAndName
      ::File.expand_path(@name + @fileExt, fullPath)
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

    def writeToFile(content, checkModTime=true)
      if checkModTime
        # refactor, bring raiseIfMTimeNotEqual back into this class
        ClWiki::Util.raiseIfMTimeNotEqual(@modTimeAtLastRead, fullPathAndName)
        unless @clientLastReadModTime.nil?
          ClWiki::Util.raiseIfMTimeNotEqual(@clientLastReadModTime, fullPathAndName)
        end
      end

      make_dirs(fullPath)
      ding_mtime
      ::File.open(fullPathAndName, 'w+') do |f|
        f.print(metadata_to_write)
        f.print(content)
      end
      ::File.utime(@metadata['mtime'], @metadata['mtime'], fullPathAndName)
      readFile
    end

    def ding_mtime
      @metadata['mtime'] = Time.now
    end

    def metadata_to_write
      @metadata.collect { |k, v| "#{k}: #{v}" }.join("\n") + "\n\n\n"
    end

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
      ::File.open(fullPathAndName, 'r') do |f|
        @modTimeAtLastRead = f.mtime
        raw_lines = f.readlines
        metadata_lines, content = split_metadata(raw_lines)
        read_metadata(metadata_lines)
        apply_metadata
        @contents = content
      end
    end

    def split_metadata(raw_lines)
      start_index = 0
      raw_lines.each_with_index do |ln, index|
        if ln.chomp.empty?
          next_line = raw_lines[index+1]
          if next_line.nil? || next_line.chomp.empty?
            start_index = index + 2
            break
          end
        end
      end
      [raw_lines[0..start_index-3], raw_lines[start_index..-1]]
    end

    def read_metadata(lines)
      @metadata = {}
      lines.each do |ln|
        key, value = ln.split(': ')
        @metadata[key] = value
      end
    end

    def apply_metadata
      @modTimeAtLastRead = Time.parse(@metadata['mtime']) if @metadata.keys.include? 'mtime'
    end
  end

  class Util
    def self.raiseIfMTimeNotEqual(mtime_to_compare, file_name)
      # reading the instance .mtime appears to take Windows DST into account,
      # whereas the static File.mtime(filename) method does not
      current_mtime = ::File.open(file_name) do |f|
        f.mtime
      end
      if mtime_to_compare != current_mtime
        raise FileModifiedSinceRead, "File has been modified since it was last read. #{mtime_to_compare} != #{current_mtime}"
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

  class FileMustUseWriteNewContent < FileError
  end
end
