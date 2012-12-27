# $Id: clWiki.rb,v 1.2 2005/02/19 04:39:10 chrismo Exp $
=begin
---------------------------------------------------------------------------
Copyright (c) 2001-2004, Chris Morris
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

CLWIKI_PATH = "C:/Apache/Apache2/htdocs/clwiki/" 
CLWIKI_URL = '/clwiki/clwikicgi.rb' 
$: << CLWIKI_PATH

require 'clwikipage'
require 'clwikiconf'

class ClWikiConvertor < BaseConvertor
  handles "txt"

  def convert_html(file_entry, f, all_entries)
    ClWikiConfiguration.load_xml(File.join(CLWIKI_PATH, $defaultConfFile))
    $wiki_conf.cgifn = CLWIKI_URL
    page_name = file_entry.file_name.sub($wiki_path, '')
    page_name.sub!($wikiPageExt, '')
    page = ClWikiPage.new(page_name)
    page.read_content(false)
    title = page_name.split('/')[-1]
    title.gsub!(/([^A-Z])([A-Z])/, '\1 \2')
    title.gsub!(/([^0-9])([0-9])/, '\1 \2')
    title.gsub!(/_/, ' ')
    title = "<a href='#{$wiki_conf.cgifn}?page=#{page_name}'>#{title}</a>"
    body  = page.content
    HTMLEntry.new(title, body, self)
  end
end

