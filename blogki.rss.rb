#!c:/ruby/bin/ruby.exe
# $Id: blogki.rss.rb,v 1.9 2005/05/30 19:27:50 chrismo Exp $
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

require 'blogki'

RSS_TOP = <<-RSSTOP
<?xml version="1.0" encoding="ISO-8859-1"?>

<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN"
                     "http://my.netscape.com/publish/formats/rss-0.91.dtd">
<rss version="2.0">
<channel>
  <title><!--TITLE--></title>
  <link><!--LINK--></link>
  <description><!--DESC--></description>
  <language>en-us</language>
RSSTOP

RSS_BOTTOM = <<-RSSBOTTOM
</channel>
</rss>
RSSBOTTOM

module CLabs
  class BlogkiRssCGI < ClWikiCGI
    def output_feed
      @cgi = CGI.new("html3")
      @queryHash = @cgi.params
    
      if @queryHash['publishTag'] && !@queryHash['publishTag'].empty?
        $wiki_conf.publishTag = @queryHash['publishTag'].to_s
      end
      $wiki_conf.cgifn = $wiki_conf.cgifn_from_rss
      
      wikiIndex = ClWikiIndexClient.new
      wikiIndex.add_hit("<a href='#{this_url}'>#{this_url.split('/')[-1]}</a>")
      
      @wiki = ClWikiFactory.new_wiki
      content, header, footer = @wiki.recentChanges
      
      print "Content-type: text/xml\n\n"
      $stdout.flush
      print content
      $stdout.flush
    end
    
    def this_url
      res = @cgi.script_name
      res ||= File.basename(__FILE__)      
    end
  end

  class BlogkiRss < ClWiki
    # refactoring to displayRecentChanges -> override recentChanges -> override recentChangeOutput
    def recentChanges(top=10)
      @show_recent_content = true
      super(top, $wiki_conf.publishTag)
    end
  
    def recentChangeOutput(pageFullName, pageModTime, pageContent)
      pageHier = pageFullName.split(/\//).delete_if { |bit| bit.empty? }
      pageName = pageHier[-1]
      category = pageHier[0..-2].join('/')
      category
      item_content = ''
      item_content << '<item>'
      item_content << "  <title>#{pageName}</title>"
      item_content << "  <link>#{base_url}?page=#{pageFullName.sub(/\/\//, '/')}</link>"
      item_content << "  <pubDate>#{CGI::rfc1123_date(pageModTime)}</pubDate>"
      item_content << "  <category>#{category}</category>"
      page_content = CGI.escapeHTML(pageContent)
      # this is a major band-aid for a piece of content at cLabs.
      page_content.gsub!(/�/, '&#8217;')
      item_content << "  <description>#{page_content}</description>"
      item_content << '</item>'
      item_content
    end
  
    def recentChangesHeader
      top = RSS_TOP
      top.sub!(/<!--TITLE-->/, $wiki_conf.recent_changes_name)
      top.sub!(/<!--LINK-->/, "#{base_url}")
      top.sub!(/<!--DESC-->/, $wiki_conf.recent_changes_name)
      top
    end
    
    def recentChangesFooter
      RSS_BOTTOM    
    end
  
    def base_url
      CGI.escapeHTML(File.join("http://#{ENV['SERVER_NAME']}", $wiki_conf.cgifn))
    end
  end
end

if __FILE__ == $0
  ClWikiFactory.wiki_class = CLabs::BlogkiRss
  ClWikiConfiguration.load_xml
  rss = CLabs::BlogkiRssCGI.new
  rss.output_feed
end
