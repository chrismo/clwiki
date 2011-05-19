#!c:/ruby/bin/ruby.exe
# $Id: blogki.editor.rb,v 1.6 2005/05/30 19:27:50 chrismo Exp $
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

module CLabs
  class BlogkiEditor < ClWiki
    def initialize(wikiPath="", confFile=$defaultConfFile)
      super(wikiPath, confFile)
      @show_recent_content = true
      $wikiConf.default_recent_changes_name = 'Blogki Editor'
    end
  
    def recentChangeOutput(pageFullName, pageModTime, pageContent)
      content = ''
      modTime = pageModTime.strftime($DATE_TIME_FORMAT)
      # this is a smell
      publishTag = $wikiConf.publishTag
      publishTag = '.*' if publishTag == '*'
      showPublishTag = (pageContent =~ /#{publishTag}/) || (pageFullName =~ /#{publishTag}/)
      @formatter.fullName = pageFullName
      content << "<tr>"
      content << "<td>#{@formatter.convertToLink(pageFullName)}</td>"
      content << "<td>#{'published' if showPublishTag}</td>"
      content << "<td align='right'>#{modTime}</td>"
      content << "</tr>"
      content
    end

    def title_name
      'blogki.editor'
    end
  end
end

if __FILE__ == $0
  # secure this file in Apache conf or else you might as well throw down
  # a regular Wiki

  ClWikiFactory.wiki_class = CLabs::BlogkiEditor
  blogki_cgi = CLabs::BlogkiCGI.new
  ClWikiConfiguration.load_xml
  $wikiConf.editable = true # override conf file
  blogki_cgi.execute
end
