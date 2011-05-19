# $Id: clwikipage.rb,v 1.68 2006/12/14 06:33:11 chrismo Exp $
=begin
---------------------------------------------------------------------------
Copyright (c) 2001-2005, Chris Morris
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

3. Neither the names Chris Morris, cLabs nor the names of contributors to
this software may be used to endorse or promote products derived from this
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS
IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------
(based on BSD Open Source License)
=end

require 'cgi'
require 'clwikifile'

$NO_WIKI_LINKS = "NoWikiLinks"
$NO_WIKI_LINKS_START = '<' + $NO_WIKI_LINKS + '>'
$NO_WIKI_LINKS_END = '</' + $NO_WIKI_LINKS + '>'

$HTML = "html"
$HTML_START = '<' + $HTML + '>'
$HTML_END = '</' + $HTML + '>'

$FIND_PAGE_NAME = "Find Page"
$FIND_RESULTS_NAME = "Find Results"

$DATE_TIME_FORMAT = "%a&nbsp;%b&nbsp;%d&nbsp;%Y %I:%M&nbsp;%p"

class ClWikiPage
  attr_reader :content, :modTime, :name, :fullName, :pagePath, :rawContent,
    :fileFullPathAndName

  @@wikiIndexClient = nil

  #Refactor clwikifile out of here into a storage class that will
  # require in the appropriate storage file clwikifile, clwikisql

  # refactor away wikiPath ... should be taken care of elsewhere, otherwise
  # ClWiki must know it, and it should be storage independent
  def initialize(fullName, wikiPath=$wikiPath)
    @fullName = fullName
    raise 'fullName must start with /' if fullName[0..0] != '/'
    @wikiPath = wikiPath
    @wikiFile = ClWikiFile.new(@fullName, @wikiPath)
    @pagePath = @wikiFile.pagePath
    @name = @wikiFile.name
  end

  # <pre> text in 1.13.2 had extra line feeds, because the \n were xformed to 
  # <br>\n, which results in two line feeds when rendered by Mozilla. 
  # The change a few versions ago inside convert_newline_to_br which started
  # converting \n to <br>\n is the culprit here. I did this for more readable 
  # html, but that does screw up <pre> sections, so it's put back now.  
  def convert_newline_to_br
    newcontent = ""
    insideHtmlTags = false
    @content.each do |substr|
      insideHtmlTags = true if (substr =~ /#{$HTML_START}/)
      insideHtmlTags = false if (substr =~ /#{$HTML_END}/)
      if ((!ClWikiPageFormatter.only_html(substr)) or (substr == "\n")) and !insideHtmlTags
        newcontent = newcontent + substr.gsub(/\n/, "<br>")
      else
        newcontent = newcontent + substr
      end
    end
    @content = newcontent
  end

  def ClWikiPage.wikiIndexClient
    @@wikiIndexClient = ClWikiIndexClient.new if !@@wikiIndexClient
    @@wikiIndexClient
  end
  
  def read_raw_content
    @rawContent = @wikiFile.content.to_s.gsub(/\r\n/, "\n")
    read_page_attributes
    ClWikiPage.wikiIndexClient.add_hit(@fullName) if $wikiConf.access_log_index
  end

  def content_never_edited?
    @wikiFile.content_is_default?
  end
  
  def delete
    @wikiFile.delete
  end
  
  def ClWikiPage.read_file_full_path_and_name(full_name, wiki_path=$wikiPath)
    wiki_file = ClWikiFile.new(full_name, wiki_path, $wikiPageExt, false)
    wiki_file.fullPathAndName
  end

  def read_page_attributes
    wikiFile = @wikiFile # ClWikiFile.new(@fullName, @wikiPath)
    @modTime = wikiFile.modTimeAtLastRead
    @fileFullPathAndName = wikiFile.fullPathAndName
  end

  def read_raw_content_with_forwarding(full_page_name)
    stack = []
    history = []
    content = ''
    final_page_name = full_page_name
    stack.push(full_page_name)
    while !stack.empty?
      this_pg_name = stack.pop
      if history.index(this_pg_name)
        pg_content = '-= CIRCULAR FORWARDING DETECTED =-'
      else
        pg = ClWikiPage.new(this_pg_name)
        pg.read_raw_content
        pg_content = pg.rawContent
        fwd_full_page_name = get_forward_ref(pg_content)
        if fwd_full_page_name
          pg_content = "Auto forwarded from /" + this_pg_name + "<hr>" + "/" + fwd_full_page_name + ":\n\n"
          stack.push fwd_full_page_name
        else
          final_page_name = this_pg_name
        end
      end
      content << pg_content << "\n"
      history << this_pg_name
    end
    [content, final_page_name]
  end

  def read_content(includeHeaderAndFooter=true, include_diff=false)
    read_page_attributes
    @content, final_page_name = read_raw_content_with_forwarding(@fullName)
    process_custom_renderers
    convert_newline_to_br
    f = ClWikiPageFormatter.new(content, final_page_name)
    @content = f.formatLinks
    if includeHeaderAndFooter
      @content = get_header + @content + get_footer
    end
    @content = CLabs::WikiDiffFormatter.format_diff(@wikiFile.diff) + @content if include_diff
    @content
  end

  def process_custom_renderers
    Dir['format/format.*'].each do |fn| require fn end
    
    ClWikiCustomFormatters.instance.process_formatters(@content, self)
  end

  def get_header
    f = ClWikiPageFormatter.new(nil, @fullName)
    f.header(@fullName)
  end

  def get_footer
    f = ClWikiPageFormatter.new(nil, @fullName)
    f.footer(self)
  end

  def get_forward_ref(content)
    content_ary = content.split("\n")
    res = (content_ary.collect { |ln| if ln.strip.empty?; nil; else ln; end }.compact.length == 1)
    if res
      res = content_ary[0] =~ /^see (.*)/i
    end

    if res
      page_name = $1
      f = ClWikiPageFormatter.new(content, @fullName)
      page_name = f.expand_path(page_name, @fullName)
      res = f.isWikiName?(page_name)
      if res
        res = ClWikiPage.page_exists?(page_name)
      end
    end
    if res
      page_name
    else
      nil
    end
  end

  def update_content(newcontent, modTime)
    wikiFile = @wikiFile # ClWikiFile.new(@fullName, @wikiPath)
    wikiFile.clientLastReadModTime = modTime
    wikiFile.content = newcontent
    if $wikiConf.useIndex != ClWikiConfiguration::USE_INDEX_NO
      wikiIndexClient = ClWikiIndexClient.new
      wikiIndexClient.reindex_page(@fullName)
    end
  end

  def ClWikiPage.page_exists?(fullPageName)
    if ($wikiConf.useIndex != ClWikiConfiguration::USE_INDEX_NO) &&
       ($wikiConf.useIndexForPageExists)
      res = ClWikiPage.wikiIndexClient.page_exists?(fullPageName)
    else
      wikiFile = ClWikiFile.new(fullPageName, $wikiPath, $wikiPageExt, false)
      res = wikiFile.file_exists?
    end
    res
  end
end

class ClWikiPageFormatter
  attr_accessor :content

  def initialize(content=nil, aFullName=nil)
    @content = content
    self.fullName = aFullName
    @wikiIndex = nil
  end

  def fullName=(value)
    @fullName = value
    if @fullName
      @fullName = @fullName[1..-1] if @fullName[0..1] == '//'
    end
  end

  def fullName
    @fullName
  end

  def header(fullPageName, searchText = '')
    searchText = File.basename(fullPageName) if searchText == ''
    pagePath, pageName = File.split(fullPageName)
    pagePath = '/' if pagePath == '.'
    dirs = pagePath.split('/')
    dirs = dirs[1..-1] if !dirs.empty? && dirs[0].empty?
    fulldirs = []
    (0..dirs.length-1).each { |i| fulldirs[i] = ('/' + dirs[0..i].join('/')) }
    if (fullPageName != $FIND_PAGE_NAME) and
       (fullPageName != $FIND_RESULTS_NAME) and
       (fullPageName != $wikiConf.recent_changes_name) and
       (fullPageName != $wikiConf.stats_name)
      head = "<b>//"
      fulldirs.each do |dir| head << "<a href=#{cgifn}?page=#{dir}>#{File.split(dir)[-1]}</a>/" end
      head << "<br>"
      head << "<font size=+3><a href=#{cgifn}?find=true&searchText=#{searchText}&type=full>#{pageName}</a></font></b><br><br>"
    else
      "<h2>" + fullPageName + "</h2>"
    end
  end

  def process_custom_footers(page)
    Dir['footer/footer.*'].each do |fn| require fn end
    
    ClWikiCustomFooters.instance.process_footers(page)
  end

  def footer(page)
    return '' if !page.is_a? ClWikiPage # blogki does this
    
    custom_footer = process_custom_footers(page)
    
    wikiName, modTime = page.fullName, page.modTime
    if modTime
      update = 'last update: ' + modTime.strftime($DATE_TIME_FORMAT)
    else
      update = ''
    end
    
    if (wikiName != $FIND_PAGE_NAME) and
      (wikiName != $FIND_RESULTS_NAME) and
      (wikiName != $wikiConf.recent_changes_name) and
      (wikiName != $wikiConf.stats_name)
      if $wikiConf.enable_cvs
        update = "<a href=#{cgifn}?page=" + wikiName + "&diff=true>diff</a> | " + update
      end
    end

    # refactor string constants
    footer = "<hr/>"
    footer << "<table border=0 width='100%'><tr><td align=left>"
    if (wikiName != $FIND_PAGE_NAME) and
       (wikiName != $FIND_RESULTS_NAME) and
       (wikiName != $wikiConf.recent_changes_name) and
       (wikiName != $wikiConf.stats_name)
      if $wikiConf.editable
        footer << ("| <a href=#{cgifn}?page=" + wikiName + "&edit=true>Edit</a> ")
      end
      footer << ("| <a href='#{mailto_url}'>Email</a> ")
      footer << "| <a href=#{reload_url}>Reload</a> <a href=#{reload_url(true)}>?</a> "
      if $wikiConf.showSourceLink
        footer << "| <a href=#{src_url}>Source</a> "
      end
    end
    footer << "|| <a href=#{cgifn}?find=true>Find</a> "
    footer << "| <a href=#{cgifn}?recent=true>Recent</a> "
    footer << "| <a href=#{cgifn}?stats=true>Stats</a> " if $wikiConf.access_log_index
    footer << "| <a href=#{cgifn}?page=/FrontPage>Home</a> "
    footer << "| <a href=#{cgifn}?about=true>About</a> " if wikiName == "/FrontPage"
    footer << "</td><td align=right>#{update}</td></tr></table>"
    return custom_footer << footer
  end

  def src_url
    "file://#{ClWikiPage.read_file_full_path_and_name(@fullName)}"
  end

  def reload_url(with_global_edit_links=false)
    result = "#{full_url}?page=#{@fullName}"
    if with_global_edit_links
      result << "&globaledits=true"
    else
      result << "&globaledits=false"
    end
  end

  def mailto_url
    "mailto:?Subject=wikifyi:%20#{@fullName}&Body=#{reload_url}"
  end

  def gsubWords
    @content.gsub(/<.+?>|<\/.+?>|[\w\\\/]+/) { |word| yield word }
  end

  def convert_relative_wikinames_to_absolute
    # do not go ahead without testing here
    #formatLinks do |word|
    #  if isWikiName?(word)
    #end

    # problem here is we should obey the NoWikiLinks and Html tag rules,
    # and those variables aren't being yielded right now. If we change
    # how the yield works, it affects the indexer. And we can't just
    # tack on additional yield params and have existing code that only
    # pays attention to the first keep working:
    #
    # irb(main):001:0> def test
    # irb(main):002:1>   yield 1,2,3
    # irb(main):003:1> end
    # nil
    # irb(main):004:0> test do |a|
    # irb(main):005:1* puts a
    # irb(main):006:1> end
    # 1
    # 2
    # 3
  end

  def formatLinks
    noWikiLinkInEffect = false
    insideHtmlTags = false

    gsubWords do |word|
      if (word[0, 1] == '<') and (word[-1, 1] == '>')
        # refactor to class,local constant, instead of global
        if (word =~ /#{$NO_WIKI_LINKS_START}/i)
          noWikiLinkInEffect = true
          word = ''
        # refactor to class,local constant, instead of global
        elsif (word =~ /#{$NO_WIKI_LINKS_END}/i)
          noWikiLinkInEffect = false
          word = ''
        end

        if (word =~ /#{$HTML_START}/i)
          insideHtmlTags = true
          word = ''
        elsif (word =~ /#{$HTML_END}/i)
          insideHtmlTags = false
          word = ''
        end
      elsif isWikiName?(word)
        if !noWikiLinkInEffect and !insideHtmlTags
          # code smell here y'all
          word = convertToLink(word) if !block_given?
        end
      end
      if block_given?
        yield word
      else
        word
      end
    end
  end

  def ClWikiPageFormatter.only_html(str)
    onlyOneTag = /\A[^<]*<[^<>]*>[^>]*\z/
    headerTagLine = /\A\s*<h.>.*<\/h.>\s*\z/
    (str =~ onlyOneTag) || (str =~ headerTagLine)
    # str.scan(/<.*>/).to_s == str.chomp
  end

  def starts_with_path_char(path)
    (path[0..0] == '/') || (path[0..1] == '//')
  end

  def do_file_expand_path(partial, reference)
    # expand_path works differently on Windows/*nix, so we have to force
    # path separators to be forward slash for consistency
    partial.gsub!(/\\/, '/')
    reference.gsub!(/\\/, '/')
    res = File.expand_path(partial, reference)

    # 1.6.8 did not put on the drive letter at the front of the path. 1.8
    # does, so we need to strip it off, because we're not really looking
    # for file system pathing here.
    res = res[2..-1] if res[0..1] =~ /.:/

    res
  end

  def expand_path(partial, reference)
    if !starts_with_path_char(partial)
      # sibling
      # "" is in [0] if partial is an absolute
      partialPieces = partial.split('/').delete_if { |p| p == "" }
      matchFound = false
      result = ''
      (partialPieces.length-1).downto(0) do |i|
        thisPartial = '/' + partialPieces[0..i].join('/')
        matchLoc = (reference.rindex(/#{thisPartial}/))
        if matchLoc
          matchFound = true
          # isn't next line stored in a Regexp globals? pre-match and match, right?
          result = reference[0..(matchLoc + thisPartial.length-1)]
          partialRemainder = partialPieces[(i+1)..-1]
          result = File.join(result, partialRemainder)
          result.chop! if result[-1..-1] == '/'
          break
        end
      end
      if !matchFound
        # take off last entry on reference path to force a sibling
        # or refactor elsewhere to pass nothing but paths into this
        # method.
        reference, = File.split(reference)
        result = do_file_expand_path(partial, reference)
      end
    else
      # to get File.expand_path to do what I need:
      #   change // to /
      #   change /  to ./
      if partial[0..1] == '//'
        partial = partial[1..-1]
      else
        partial = '.' + partial
      end
      result = do_file_expand_path(partial, reference)
    end

    # if ('/a/b', '/') passed, then '//' ends up at front because
    # this is not illegal at the very first in File.expand_path
    result = result[1..-1] if result[0..1] == '//'
    result
  end

  def do_fullparts_displayparts_assertion(fullparts, displayparts)
    # this is complicated, unfortunately. expand_path does not ever return
    # // at the front of an absolute path, though it should. I can't change
    # it right now cuz that's a major change.

    # in the case where the display name is absolute with //, the full
    # name will only have one slash up front, so we need to tweak that case
    # temporarily to get this assertion to work

    # we also need to eliminate slash positions, which shows as empty
    # strings in these arrays
    afullparts = fullparts.dup
    afullparts.delete_if do |part| part.empty? end

    adispparts = displayparts.dup
    adispparts.delete_if do |part| part.empty? end

    if afullparts[(-adispparts.length)..-1] != adispparts
      raise "assertion failed. displayparts <#{adispparts.inspect}> should be " +
        "tail end of fullparts <#{afullparts.inspect}>"
    end
  end

  def format_for_dir_and_page_links(pageFullName, pageName)
    fullparts = pageFullName.split('/')
    displayparts = pageName.split('/')
    do_fullparts_displayparts_assertion(fullparts, displayparts)
    result = ''
    displayparts.each do |part|
      if !part.empty?
        fullpagelink = fullparts[0..fullparts.index(part)].join('/')
        result << '/' if !result.empty? && result[-1..-1] != '/'
        result << "<a href=#{cgifn}?page=#{fullpagelink}>#{part}</a>"
      else
        result << '/'
      end
    end
    result
  end

  def cgifn
    $wikiConf.cgifn if $wikiConf
  end

  def full_url
    ($wikiConf.url_prefix + cgifn) if $wikiConf
  end

  def convertToLink(pageName)
    # We need to calculate its fullPageName based on the ref fullName in case
    # the pageName is a relative reference
    pageFullName = expand_path(pageName, @fullName)
    if ClWikiPage.page_exists?(pageFullName)
      format_for_dir_and_page_links(pageFullName, pageName)
    else
      @wikiIndex = ClWikiIndexClient.new if @wikiIndex.nil?
      titles_only = true
      hits = @wikiIndex.search(pageName, titles_only)
      hits = GlobalHitReducer.reduce_to_exact_if_exists(pageName, hits)

      case hits.length
      when 0
        result = pageName
      when 1
        result = "<a href=#{cgifn}?page=#{hits[0]}>#{pageName}</a>"
      else
        result = "<a href=#{cgifn}?find=true&searchText=#{pageName}&type=title>#{pageName}</a>"
      end

      if ($wikiConf.editable) && ((hits.length == 0) || ($wikiConf.global_edits))
        result <<
          "<a href=#{cgifn}?page=" + pageFullName + "&edit=true>?</a>"
      end
      result
    end
  end

  def isWikiName?(string)
    allWikiNames = true
    names = string.split(/[\\\/]/)

    # if first character is a slash, then split puts an empty string into names[0]
    names.delete_if { |name| name.empty? }
    allWikiNames = false if names.empty?
    names.each do |name|
      allWikiNames =
        (
          allWikiNames and

          # the number of all capitals followed by a lowercase is greater than 1
          (name.scan(/[A-Z][a-z]/).length > 1) and

          # the first letter is capitalized or slash
          (
           (name[0,1] == name[0,1].capitalize) or (name[0,1] == '/') or (name[0,1] == "\\")
          ) and

          # there are no non-word characters in the string (count is 0)
          # ^[\w|\\|\/] is read:
          # _____________[_____  _^_  ____\w_________  _|  __\\______  _|  ___\/________]
          # characters that are  not  word characters  or  back-slash  or  forward-slash
          # (the not negates the *whole* character set (stuff in brackets))
          (name.scan(/[^\w\\\/]/).length == 0)
        )
    end
    return allWikiNames
  end
end

require 'singleton'

class ClWikiCustomFooters
  include Singleton

  def register(class_ref)
    @footers ||= []
    @footers << class_ref
  end
  
  def process_footers(page)
    content = ''
    @footers.each do |f|
      content << f.footer_html(page)
    end if @footers
    return content
  end
end

# to create your own custom footer, see any of the files in the ./footer
# directory and imitate. 
class ClWikiCustomFooter
end

class ClWikiCustomFormatters
  include Singleton
  
  def register(class_ref)
    @formatters ||= []
    @formatters << class_ref
  end
  
  def process_formatters(content, page)
    @formatters.each do |f|
      if content =~ f.match_re
        content.gsub!(f.match_re) { |match| f.format_content(match, page) }
      end
    end if @formatters
  end
end

# to create your own custom formatter, see any of the files in the ./format
# directory and imitate. 
class ClWikiCustomFormatter
end

class GlobalHitReducer
  def GlobalHitReducer.reduce_to_exact_if_exists(term, hits)
    reduced = hits.dup
    reduced.delete_if do |hit|
      parts = hit.split('/')
      exact = (parts[-1] =~ /^#{term}$/i)
      !exact
    end

    if !reduced.empty?
      reduced
    else
      hits
    end
  end
end
   
module CLabs
  class WikiDiffFormatter    
    def WikiDiffFormatter.format_diff(diff)
      "<b>Diff</b><br><pre>\n#{CGI.escapeHTML(diff)}\n</pre><br><hr=width\"50%\">"
    end
  end
end
  # 14,15c14
  # < yo yo mallll
  # < lntttnnllnlll;;;
  # ---
  # > lntttnnllnlllchange here - delete above
  # 17c16,18
  # < /TestPage
  # \ No newline at end of file
  # ---
  # > /TestPage
  # >
  # > THis is new text.
  # \ No newline at end of file
  
  # 15a16
  # > added
  # \ No newline at end of file    
  
  # 18d17
  # < THis is new text.
  # \ No newline at end of file
  
  # look for the d in the line and translate to Removed/Deleted
  # look for c -> Changed
  # look for a -> Added
  
  # color all lines starting with < with one color (UseMod default is yellow - old stuff)
  # color all lines starting with > with another (UseMod default is green)
  
  # $DiffColor1  = '#ffffaf';       # Background color of old/deleted text
  # $DiffColor2  = '#cfffcf';       # Background color of new/added text
