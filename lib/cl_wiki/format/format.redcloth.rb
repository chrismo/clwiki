$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require 'redcloth.clwiki'

class FormatRedCloth < ClWikiCustomFormatter
  def FormatRedCloth.match_re
    /.+/m # /.*/m matches twice for some reason
  end

  LITE = false
  
  def FormatRedCloth.format_content(content, page)
    File.open(File.join(File.dirname(__FILE__), 'sample.content.txt'), 'w+') do |f| f.print content end
    content = RedCloth.new(content)
    content.to_html(LITE) + "<hr>redcloth was here...<hr>"
  end
end

# ClWikiCustomFormatters.instance.register(FormatRedCloth)