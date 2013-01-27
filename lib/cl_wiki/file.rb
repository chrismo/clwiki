require 'fileutils'
require 'time'

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
      cvs_remove
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
      cvs_commit
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
        do_cvs_commit(::File.dirname(dir), ::File.basename(dir))
      end
    end

    def cvs_commit
      if $wiki_conf.enable_cvs
        dir = ::File.dirname(fullPathAndName)
        fn = ::File.basename(fullPathAndName)
        do_cvs_commit(dir, fn)
      end
    end

    def cvs_remove
      if $wiki_conf.enable_cvs
        dir = File.dirname(fullPathAndName)
        fn = File.basename(fullPathAndName)
        do_cvs_remove(dir, fn)
      end
    end

    def do_cvs_commit(dir, item_name)
      if $wiki_conf.enable_cvs
        cvsout = ''
        Dir.chdir(dir) do
          # always adding for now. If it exists, no worries ... could be
          # performance drag, but it's a sure thang for now.
          cvsout << "\n" << Time.now.to_s << "\n"
          cvsout << dir << "\n"
          cvsout << 'CVS_RSH = ' + ENV['CVS_RSH'].inspect << "\n"
          cmd = "cvs.exe add -m auto #{item_name} 2>&1"
          cvsout << cmd << "\n"
          cvsout << `#{cmd}`
          cmd = "cvs.exe commit -m auto #{item_name} 2>&1"
          cvsout << cmd << "\n"
          cvsout << `#{cmd}`
        end
        cvs_log(cvsout)
      end
    end

    def do_cvs_remove(dir, item_name)
      if $wiki_conf.enable_cvs
        cvsout = ''
        Dir.chdir(dir) do
          cvsout << "\n" << Time.now.to_s << "\n"
          cvsout << dir << "\n"
          cvsout << 'CVS_RSH = ' + ENV['CVS_RSH'].inspect << "\n"
          cmd = "cvs.exe remove -f #{item_name} 2>&1"
          cvsout << cmd << "\n"
          cvsout << `#{cmd}`
          cmd = "cvs.exe commit -m \"removing unused page\" #{item_name} 2>&1"
          cvsout << cmd << "\n"
          cvsout << `#{cmd}`
        end
        cvs_log(cvsout)
      end
    end

    def cvs_log(log_content)
      if $wiki_conf.cvs_log
        File.open($wiki_conf.cvs_log, 'a+') do |f|
          f.puts log_content
        end
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

    def diff
      get_diff
    end

    def get_diff
      if $wiki_conf.enable_cvs
        stat_out = ''; cvs_pwd = ''
        fn = File.basename(fullPathAndName)
        Dir.chdir(fullPath) do
          stat_out = `cvs status #{fn}`
        end
        cvs_log(stat_out)
        cur_rev = stat_out.scan(/Working revision:\t(\S*)/).to_s
        prev_rev = CLabs::Util::Cvs.inc_rev(cur_rev, -1)

        diff = ''
        Dir.chdir(fullPath) do
          cmd = "cvs diff -r #{prev_rev} -r #{cur_rev} #{fn}"
          cvs_log(cmd)
          diff = `#{cmd}`
          diff.gsub!(/^\\ No newline at end of file\n/, '')
          cvs_log(diff)
        end
        diff
      end
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
        raise FileModifiedSinceRead, "File has been modified since it was last read."
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

module CLabs
  module Util
    class Cvs
      def Cvs.inc_rev(rev_str, inc)
        rev_parts = rev_str.split('.')
        pre, post = [rev_parts[0..-2].join('.'), rev_parts[-1].to_i]
        post += inc
        pre + '.' + post.to_s
      end
    end
  end
end
