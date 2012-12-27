#!c:/ruby/bin/ruby.exe
# $Id: clwikicgi.rb,v 1.68 2005/05/30 19:27:50 chrismo Exp $
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
require 'clwiki'
require 'clwikiconf'

class ClWikiCGI
  def get_page_name
    @pageName = @queryHash['page'].to_s
    @pageName = '/' + @pageName if @pageName[0..0] != '/'
  end

  def get_script_name
    # ENV['SCRIPT_NAME']
    # in case I get rid of 'cgi'
    res = @cgi.script_name
    res ||= File.basename(__FILE__)
  end

  def execute
    begin
      @cgi = CGI.new("html3")
      @wiki = ClWikiFactory.new_wiki
      $wiki_conf.cgifn = get_script_name.split('/')[-1]
      url_path = get_script_name.split('/')[0..-2].join('/') + '/'
      $wiki_conf.url_prefix = "http://#{ENV['SERVER_NAME']}#{url_path}"

      @post = (ENV['REQUEST_METHOD'] == "POST")
      @editConflict = false
      if @post
        # on a post, cgi.params are form fields, not query string
        @queryHash = CGI.parse(ENV['QUERY_STRING'])
        @find = (@queryHash['find'].to_s == "true")
        @saveButton = @cgi.params.has_key? "save"
        @saveEditButton = @cgi.params.has_key? "saveedit"
        if !@find && $wiki_conf.editable
          get_page_name
          newContent = @cgi['wikiContent']
          clientModTime = Time.at(@cgi['clientModTime'].to_s.to_i)
          begin
            @wiki.updatePage(@pageName, clientModTime, newContent)
          rescue ClWikiFileModifiedSinceRead
            @editConflict = true
          end
        end
        @edit = @saveEditButton
      else
        @queryHash = @cgi.params
        get_page_name
        @edit = (@queryHash['edit'].to_s == "true") && $wiki_conf.editable
      end

      processQueryHash
      
      @debug = (@queryHash['debug'].to_s == "true")
      @find = (@queryHash['find'].to_s == "true")
      @recent = (@queryHash['recent'].to_s == "true")
      @stats = (@queryHash['stats'].to_s == "true")
      @about = (@queryHash['about'].to_s == "true")
      @searchText = @queryHash['searchText'].to_s
      $wiki_conf.global_edits = (@queryHash['globaledits'].to_s == "true")
      @show_diff = (@queryHash['diff'].to_s == "true")
      if @searchText.empty?
        @searchText = @cgi['searchText']
      end
      @searchType = @queryHash['type'].to_s
      @searchUseIndex = (@queryHash['useIndex'].to_s =~ /true/i)
      @searchTitleOnly = (@queryHash['titleOnly'].to_s =~ /true/i)

      # this bit here stinketh
      if @about
        doAbout
      elsif @editConflict
        displayEditConflictPage
      elsif @edit
        displayPageEdit
      elsif @find
        displayPageFind
      elsif @recent
        displayRecentChanges
      elsif @stats
        displayStats
      else
        displayPage
      end
    rescue Exception => e
      print "Content-type: text/html\r\n\r\n"
      print "Error occurred: " + e.message + "<br><br>\r\n\r\n"
      print e.backtrace.join("<br>\n")
    ensure
      $wiki_conf.wait_on_threads
    end
  end

  def processQueryHash
    # can be overridden for additional custom processing 
  end
  
  def debugOutput
    if @debug
      @cgi.pre {
        "@queryHash: "              + @queryHash.inspect      + "\n" +
        "@queryHash['page'].to_s: " + @queryHash['page'].to_s + "\n" +
        "@pageName: "               + @pageName               + "\n" +
        "@edit: "                   + @edit.to_s              + "\n" +
        "@post: "                   + @post.to_s              + "\n" +
        "@debug: "                  + @debug.to_s             + "\n" +
        "@about: "                  + @about.to_s             + "\n" +
        "@find: "                   + @find.to_s              + "\n" +
        "@saveButton: "             + @saveButton.to_s        + "\n" +
        "@saveEditButton: "         + @saveEditButton.to_s    + "\n" +

        CGI::escapeHTML(
          # params are query string unless call is a form post, then they're
          # form fields
          "params: " + @cgi.params.inspect + "\n" +
          "cookies: " + @cgi.cookies.inspect + "\n" +
          ENV.collect() do |key, value|
            key + " --> " + value + "\n"
          end.join("")
        )
      }
    else
      ""
    end
  end

  def displayPage
    page = @wiki.displayPage(@pageName, !$wiki_conf.template, @show_diff)
    content = page.content

    title = "#{@wiki.title_name}: " + @pageName

    if !$wiki_conf.template
      display(title, content)
    else
      display(title, content, page.get_header, page.get_footer)
    end
  end

  def displayEditConflictPage
    exit if !$wiki_conf.editable

    title = "#{@wiki.title_name}: " + @pageName
    content =
      "Another user has edited this page since you loaded it. " +
      "Navigate back to the previous page, copy your edits to a local " +
      "file, then reload the page and merge your changes with the new " +
      "version of the page."

    display(title, content)
  end

  def display(title, body, header='', footer='')
    if !$wiki_conf.template
      @cgi.out {
        @cgi.html {
          @cgi.head {
            @cgi.title{ title } +
            displayEmbeddedCss
          } +
          '<body>' +
            header + body + footer + debugOutput +
          '</body>'
        }
      }
    else
      templateLines = File.readlines($wiki_conf.template)
      templateLines.collect! do |ln|
        ln.sub!(/<!--#clwiki_include_title-->/, title)
        ln.sub!(/<!--#clwiki_include_style-->/, displayEmbeddedCss)
        ln.sub!(/<!--#clwiki_include_header-->/, header)
        ln.sub!(/<!--#clwiki_include_footer-->/, footer)
        ln.sub!(/<!--#clwiki_include_body-->/, body)
        ln
      end
      @cgi.out { templateLines.join("\n") }
    end
  end

  def displayPageEdit
    exit if !$wiki_conf.editable

    title = "#{@wiki.title_name}: editing " + @pageName

    # pretty output screws with the textarea contents
    content, header, footer = @wiki.displayPageEdit(@pageName)
    display(title, content, header, footer)

    # leaving out this attempt at no-caching, don't know if it ever did anything

    #           "<meta http-equiv='pragma' content='no-cache'></meta>"
  end

  def displayPageFind
    title = "#{@wiki.title_name}: Find Pages"
    if (!@searchType) || @searchType.empty?
      searchType = 'full'
      searchType = 'title' if @searchTitleOnly
      searchType << 'slow' if !@searchUseIndex
    else
      searchType = @searchType
    end
    content, header, footer = @wiki.displayPageFind(@searchText, searchType)
    display(title, content, header, footer)
  end

  def displayRecentChanges
    title = "#{@wiki.title_name}: Recent Changes"
    content, header, footer = @wiki.recentChanges
    display(title, content, header, footer)
  end
  
  def displayStats
    title = "#{@wiki.title_name}: Stats"
    content, header, footer = @wiki.stats
    display(title, content, header, footer)
  end

  def displayEmbeddedCss
    if !$wiki_conf.cssHref
      <<-CSS
        <STYLE TYPE="text/css" MEDIA="screen" TITLE="clWiki">
        <!--
        BODY { font-size: x-small; font-family: Verdana; Arial; }
        TD { font-size: x-small; font-family: Verdana; Arial; }
        PRE {font-size: 100%; }
        pageName { font-size: larger; }
        -->
        </STYLE>
      CSS
    else
      <<-CSS
        <link rel="StyleSheet" href="#{$wiki_conf.cssHref}" type="text/css" media="screen">
      CSS
    end
  end

  def doAbout
    title = "About clWiki"
    mtime = File.stat(__FILE__).mtime
    mtime_stamp = "#{mtime.year}.#{mtime.month}.#{mtime.day}"
    content =
      "<a href=http://www.clabs.org>cLabs</a> Wiki (clWiki)" + "<br>" +
      "Version #{ClWiki::VERSION.to_s} (#{mtime_stamp})<br>" + 
      "by Chris Morris" + "<br><br>" +
      @cgi.pre {
        <<-THE_LICENSE
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
        THE_LICENSE
      }
    display(title, content)
  end
end

if __FILE__ == $0
  wiki = ClWikiCGI.new
  wiki.execute
end
