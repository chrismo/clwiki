require 'cgi'

class FormatPreBlockquote < ClWikiCustomFormatter
  def FormatPreBlockquote.match_re
    /\[p\].*?\[\/p\]/mi
  end
  
  def FormatPreBlockquote.format_content(content, page)
    content = CGI.escapeHTML(content)
    content.gsub!(/\[p\]/i, "<blockquote><pre>")
    content.gsub!(/\[\/p\]/i, "</pre></blockquote>")
  end
end

ClWikiCustomFormatters.instance.register(FormatPreBlockquote)
