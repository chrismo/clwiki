# $Id: clwikifile.rb,v 1.17 2005/05/30 19:27:50 chrismo Exp $
=begin
--------------------------------------------------------------------------
Copyright (c) 2001-2005, Chris Morris
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the names Chris Morris, cLabs nor the names of contributors to this
software may be used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
(based on BSD Open Source License)
=end

require 'ftools'

$wikiPageExt = '.txt'

class ClWikiFile
  attr_reader :name, :fileExt, :wikiRootPath, :pagePath, :modTimeAtLastRead    
  attr_accessor :clientLastReadModTime

  def initialize(fullPageName, wikiRootPath, fileExt=$wikiPageExt, autocreate=true)
    # fullPageName must start with / ?
    @wikiRootPath = wikiRootPath
    fullPageName = ClWikiUtil.convertToNativePath(fullPageName)
    raise 'fullPageName must start with /' if fullPageName[0..0] != '/'
    @pagePath, @name = File.split(fullPageName)
    @pagePath = '/' if @pagePath == '.'
    @fileExt = fileExt
    if autocreate
      if file_exists?
        readFile
      else
        writeToFile(default_content, false)
      end
    end
  end

  def content_is_default?
    puts "#{@contents.to_s[0..30].inspect} #{default_content.inspect}"
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
    res = File.expand_path(File.join(@wikiRootPath, @pagePath))
    raise 'no dirs in fullPath' if res.split('/').empty? 
    res
  end
  
  def fullPathAndName
    File.expand_path(@name + @fileExt, fullPath)
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
      ClWikiUtil.raiseIfMTimeNotEqual(@modTimeAtLastRead, fullPathAndName)
      if not @clientLastReadModTime.nil? 
        ClWikiUtil.raiseIfMTimeNotEqual(@clientLastReadModTime, fullPathAndName)
      end
    end

    make_dirs(fullPath)
    content.gsub!(/\r\n/, "\n") if PLATFORM =~ /mswin/
    File.open(fullPathAndName, 'w+') do |f|
      f.print(content)
    end
    cvs_commit
    readFile
  end

  def make_dirs(dir)
    # need to commit each dir as we make it, which is why we just don't
    # call File::makedirs. Core code copied from ftools.rb
    parent = File.dirname(dir)
    return if parent == dir or FileTest.directory? dir
    make_dirs parent unless FileTest.directory? parent
    if File.basename(dir) != ""
      Dir.mkdir dir, 0755
      do_cvs_commit(File.dirname(dir), File.basename(dir))
    end
  end
  
  def cvs_commit
    if $wikiConf.enable_cvs
      dir = File.dirname(fullPathAndName)
      fn = File.basename(fullPathAndName)
      do_cvs_commit(dir, fn)
    end
  end

  def cvs_remove
    if $wikiConf.enable_cvs
      dir = File.dirname(fullPathAndName)
      fn = File.basename(fullPathAndName)
      do_cvs_remove(dir, fn)
    end
  end
  
  def do_cvs_commit(dir, item_name)
    if $wikiConf.enable_cvs
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
    if $wikiConf.enable_cvs
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
    if $wikiConf.cvs_log
      File.open($wikiConf.cvs_log, 'a+') do |f| f.puts log_content end 
    end
  end
  
  def readFile
    File.open(fullPathAndName, 'r') do |f|
      @contents = f.readlines
      @modTimeAtLastRead = f.mtime
    end
  end
  
  def diff
    get_diff
  end
  
  def get_diff
    if $wikiConf.enable_cvs
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

class ClWikiUtil
  def ClWikiUtil.raiseIfMTimeNotEqual(mtime_to_compare, file_name)
    # reading the instance .mtime appears to take Windows DST into account,
    # whereas the static File.mtime(filename) method does not
    current_mtime = File.open(file_name) do |f| f.mtime end
    if mtime_to_compare != current_mtime
      raise ClWikiFileModifiedSinceRead, 
        "File has been modified since it was last read."
    end
  end
  
  def ClWikiUtil.convertToNativePath(path)
    newpath = path.gsub(/\//, File::SEPARATOR)
    newpath = newpath.gsub(/\\/, File::SEPARATOR)
    return newpath
  end
end

class ClWikiFileError < Exception
end

class ClWikiFileModifiedSinceRead < ClWikiFileError
end

class ClWikiFileMustUseWriteNewContent < ClWikiFileError
end 
