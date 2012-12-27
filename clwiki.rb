# $Id: clwiki.rb,v 1.94 2006/12/14 02:12:58 chrismo Exp $
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
require 'clwikiindex'
require 'clwikipage'
require 'clwikiconf'
require 'findinfile'
require 'ftools'

$wiki_path = ''

# need to fully refactor ClWikiFile out and have ClWiki only use ClWikiPage
# ClWiki -> ClWikiPage -> ClWikiFile
# names are getting confused and mixed up
class ClWiki
  # cl/util/version is no more, but don't have time to gem-ify this properly, so just going back to manual for now.
  VERSION = '1.16.0'

  attr_reader :name, :wikiPath, :wrapWidth, :wrap

  FRONT_PAGE_NAME = "/FrontPage"

  def initialize(wikiPath="", confFile=$defaultConfFile)
    @confFile = confFile
    if wikiPath == "" then
      @wikiPath = readConf("wikiPath")
    else
      @wikiPath = wikiPath
    end
    # shortcut -- need a Singleton conf obj
    $wiki_path = @wikiPath
    if !FileTest.directory?(@wikiPath)
      File::makedirs(@wikiPath)
    end

    @formatter = ClWikiPageFormatter.new
    @show_recent_content = false
  end

  def title_name
    'clWiki'
  end

  def isWikiName?(wikiName)
    @formatter.isWikiName?(wikiName)
  end

  def frontPageIfBadName(wikiName)
    if (wikiName.empty?) or (!isWikiName?(wikiName))
      wikiName = FRONT_PAGE_NAME
    else
      wikiName
    end
  end

  def displayPage(wikiName, includeHeaderFooter=true, include_diff=false)
    wikiName = frontPageIfBadName(wikiName)
    if !$wiki_conf.editable and !ClWikiPage.page_exists?(wikiName)
      wikiName = FRONT_PAGE_NAME
    end
    wikiPage = ClWikiPage.new(wikiName)
    wikiPage.read_content(includeHeaderFooter, include_diff)
    wikiPage
  end

  def displayPageEdit(wikiName)
    wikiName = frontPageIfBadName(wikiName)
    wikiPage = ClWikiPage.new(wikiName, @wikiPath)
    wikiPage.read_raw_content
    
    # see note at end of source file called Escaping HTML.
    form = <<-FORMCONTENT
      <FORM METHOD="post" ACTION="#{@formatter.cgifn}?page=#{wikiName}">
      <TEXTAREA NAME="wikiContent" ROWS="#{$wiki_conf.edit_rows}" COLS="#{$wiki_conf.edit_cols}">#{CGI.escapeHTML(wikiPage.rawContent)}</TEXTAREA>
      <INPUT NAME="clientModTime" TYPE="hidden" VALUE="#{wikiPage.modTime.to_i.to_s}">
      <BR>
      <INPUT TYPE="submit" VALUE="Save" NAME="save"> <INPUT TYPE="submit" VALUE="Save and Continue Editing" NAME="saveedit">
      </FORM>
    FORMCONTENT
    [form, @formatter.header(wikiName), '']
  end

  def displayPageFind(searchText, searchType)
    cgi = CGI.new("html3")
    if searchText.empty?
      [
        cgi.form("get", "") {
          "Search:<br> " +
          "<input type='hidden' name='find' value='true'>" +
          cgi.text_field("searchText") + " " +
          cgi.checkbox("titleOnly", "true", false) + "Titles Only " +
          cgi.checkbox("useIndex", "true", true) + "Use Index* <br>" +
          cgi.submit("Find")
        } +
        "<blockquote>" +
        "Multiple terms will be AND-ed together. Entering " +
        "\"this that\" " +
        "will find only pages with both <i><b>this</b></i> and <b><i>that</i></b> in the content.<br>" +
        "<br>" +
        "Partial matches are returned. Entering " +
        "\"the\" " +
        "will match <i><b>the</b></i>, <i><b>the</b>ater</i>, <i>soo<b>the</b></i>, <i>o<b>the</b>r</i>, etc.<br>" +
        "<br>" +
        "* Searching without the index will instruct clWiki to crawl " +
        "the file system directly, which is typically much slower. " +
        "This option is only provided in " +
        "case of a suspected flaw in the index." +
        "</blockquote>",
        @formatter.header("Find Page"),
        @formatter.footer("Find Page")
      ]
    else
      displayFindResults(searchText.to_s, searchType)
    end
  end

  # refactor so not passing same params twice?
  def displayFindResults(searchText, searchType)
    # cgi = CGI.new("html3")
    if !(searchType =~ /slow/i)
      displayFindResultsUsingWikiIndex(searchText, searchType)
    else
      finder = FindInFile.new(@wikiPath)

      page = ''
      if searchType == 'titleslow'
        finder.find(searchText, FindInFile::FILE_NAME_ONLY)
      elsif searchType == 'fullslow'
        finder.find(searchText)
      else
        raise "error: unknown searchType: #{searchType}"
      end
      finder.files.each do | filename |
        wikiName = filename.sub($wikiPageExt, '')
        # wikiName = '/' + wikiName if wikiName[0..0] != '/'
        # refactor to use ClWikiPage.convertToLink
        page << "<a href=?page=#{'/' + wikiName}>#{'//' + wikiName}</a><br>"
      end
      [page, @formatter.header("Find Results"), @formatter.footer("Find Results")]
    end
  end

  # refactor so not passing same params twice?
  def displayFindResultsUsingWikiIndex(searchText, searchType)
    page = ''
    wikiIndex = ClWikiIndexClient.new
    hits = wikiIndex.search(searchText, (searchType == 'title'))

    page << "search type: <b>#{searchType}</b> searching for: <b>#{searchText}</b> total hits: <b>#{hits.length.to_s}</b><hr>"
    hits.each do |fullName|
      @formatter.fullName = fullName
      page << "#{@formatter.convertToLink('/' + fullName)}<br>"
    end

    [page, @formatter.header("Find Results"), @formatter.footer("Find Results")]
  end

  class TimeNamePair
    attr_accessor :time, :pageName
    
    def initialize(time, pageName)
      @time, @pageName = time, pageName
    end
  end
  
  def recentChangesHeader
    "<table border='0' width='100%'>"  
  end
  
  def recentChangesFooter
    "</table>"
  end
  
  # blogki subclasses can specify a publishTag to filter the recent list on
  def recentChanges(top=30, publishTag=nil)
    publishTag = nil if publishTag == '*'
  
    wikiIndex = ClWikiIndexClient.new
    content = ''
    content << recentChangesHeader
    
    # this is supposed to be the Wiki view, not the blogki view.
    if publishTag
      # converted hash to array in order to sort most recent at top
      sorted_hash = wikiIndex.sort_hits_by_recent(wikiIndex.search(publishTag), top)
    else
      sorted_hash = wikiIndex.recent(top)
    end
    
    time_names = []
    sorted_hash.each do |time_name_ary|
      time = time_name_ary[0]
      pageNames = time_name_ary[1]
      pageNames.each do |pageName|
        time_names << TimeNamePair.new(time, pageName)
      end
    end
      
    time_names.each do |timeNamePair|
      pageName = '/' + timeNamePair.pageName
      pageModTime = timeNamePair.time
      if @show_recent_content
          # we don't need want to record page hits here
        $wiki_conf.override_access_log_index
        begin
          pg = ClWikiPage.new(pageName)
          pg.read_content(false)
          pageContent = pg.content
          pageModTime = pg.modTime
        ensure
          $wiki_conf.restore_access_log_index
        end
      else
        pageContent = nil
      end
      content << recentChangeOutput(pageName, pageModTime, pageContent)
    end
    content << recentChangesFooter
    [content,
     @formatter.header($wiki_conf.recent_changes_name) + "<hr>",
     @formatter.footer($wiki_conf.recent_changes_name)]
  end
  
  def recentChangeOutput(pageFullName, pageModTime, pageContent)
    content = ''
    if $wiki_conf.useGmt
      modTime = pageModTime.gmtime.strftime($DATE_TIME_FORMAT) + '&nbsp;GMT'
    else
      modTime = pageModTime.strftime($DATE_TIME_FORMAT)
    end
    @formatter.fullName = pageFullName
    content << "<tr><td>#{@formatter.convertToLink(pageFullName)}</td><td align='right'>#{modTime}</td></tr>"
    if pageContent
      content << "<tr><td colspan='2'><blockquote>#{pageContent}</blockquote></td></tr>"
    end
    content << "<tr><td>&nbsp;</td></tr><tr><td>&nbsp;</td></tr>" if pageContent
    content
  end

  def stats(top=30)
    wikiIndex = ClWikiIndexClient.new
    content = ''
    content << "<table border='0'>"
    content << statsTitleRow
    current = 1
    wikiIndex.hit_summary.each do |page_hits_ary_ary|
      pageName = page_hits_ary_ary[0].to_s
      if pageName !~ /<a href/
        pageName = '/' + pageName
      end
      hits_ary = page_hits_ary_ary[1]
      hit_count = hits_ary.length
      content << statsOutput(pageName, hits_ary) 
      current += 1
      break if current >= top
    end
    content << "</table>"
    [content,
     @formatter.header($wiki_conf.stats_name) + "<hr>",
     @formatter.footer($wiki_conf.stats_name)]
  end
  
  def statsTitleRow
    content = ''
    content << "<tr>"
      content << "<td><b>Page</b></td>"
      content << statsColBuffer
      content << "<td align='center'><b>Total Hits</b></td>"
      content << statsColBuffer
      content << "<td align='center'><b>#{statsDateHeader(0)}</b></td>"
      content << statsColBuffer
      content << "<td align='center'><b>#{statsDateHeader(1)}</b></td>"
      content << statsColBuffer
      content << "<td align='center'><b>#{statsDateHeader(2)}</b></td>"
    content << "</tr>"
    content
  end
  
  def statsColBuffer
    "<td>&nbsp;</td><td>&nbsp;</td>"
  end
  
  def statsDateHeader(months_ago)
    mon = Time.now.mon - months_ago
    yr = Time.now.year
    while mon < 1 do
      yr -= 1
      mon += 12
    end
    "#{mon}/#{yr}"
  end
  
  def statsOutput(pageFullName, hits_ary)
    content = ''
    if pageFullName !~ /<a href/
      @formatter.fullName = pageFullName
      pageLink = @formatter.convertToLink(pageFullName)
    else
      pageLink = pageFullName
    end
    content << "<tr>"
      content << "<td>#{pageLink}</td>"
      content << statsColBuffer
      content << "<td align='center'>#{hits_ary.length}</td>"
      content << statsColBuffer
      content << "<td align='center'>#{hits_ary.dup.delete_if { |t| t.month != Time.now.month }.length}</td>"
      content << statsColBuffer
      content << "<td align='center'>#{hits_ary.dup.delete_if { |t| t.month != Time.now.month - 1 }.length}</td>"
      content << statsColBuffer
      content << "<td align='center'>#{hits_ary.dup.delete_if { |t| t.month != Time.now.month - 2 }.length}</td>"
    content << "</tr>"
    content
  end
  
  def updatePage(wikiName, readMTime, newContent)
    wikiPage = ClWikiPage.new(wikiName)
    wikiPage.update_content(newContent, readMTime)
  end

  def readConf(item)
    ClWikiConfiguration.load_xml(@confFile) if $wiki_conf == nil
    $wiki_conf.send(item)
  end
end

class ClWikiFactory
  @@wiki_class = ClWiki

  def ClWikiFactory.new_wiki(wikiPath="", confFile=$defaultConfFile)
    @@wiki_class.new(wikiPath, confFile)
  end

  def ClWikiFactory.wiki_class=(value)
    @@wiki_class = value
  end
end

=begin

Escaped HTML

If the text inserted into a page is escapedHTML, clWiki will store it 
as-is in the underlying .txt file and re-display it without any problem.

However, on an edit page, the textarea control will unescape the text put 
into it. So even though the text put into it is escaped entities, the 
browser unescapes them when rendering in the textarea control. So the code
in displayPageEdit escapes the text an additional time, so when the browser
unescapes the text going into the textarea, it's back to where we started.

EXAMPLE:

User enters the following into a page edit initially:

  &lt;br&gt;
  
The content of the .txt file is:

  &lt;br&gt;

When rendered in normal display, the following is displayed literally

  <br>

And when rendered in a textarea display, that same text would also appear:

  <br>

... but then saved back to the .txt file as:

  <br>

... being rendered as a line-break on the next rendering.

So ClWiki escapes the text a second time before rendering it in the textarea:

  &amp;lt;br&amp;gt;

... which then allows it to show as its originally entered state:

  &lt;br&gt;
  
=end  
