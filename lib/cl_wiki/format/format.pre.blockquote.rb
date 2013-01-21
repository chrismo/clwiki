require 'cgi'

class FormatPreBlockquote < ClWiki::CustomFormatter
  def FormatPreBlockquote.match_re
    /\[p\].*?\[\/p\]/mi
  end
  
  def FormatPreBlockquote.format_content(content, page)
    content = CGI.escapeHTML(content)
    content.gsub!(/\[p\]/i, "<blockquote><pre>")
    content.gsub!(/\[\/p\]/i, "</pre></blockquote>")
  end
end

ClWiki::CustomFormatters.instance.register(FormatPreBlockquote)
