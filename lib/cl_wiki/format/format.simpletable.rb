class FormatSimpleTable < ClWiki::CustomFormatter
  def FormatSimpleTable.match_re
    /<simpletable.*?>.*?<\/simpletable>/m
  end

  def FormatSimpleTable.format_content(content, page = nil)
    table_attr = content.scan(/<simpletable(.*?)>/m).to_s.strip
    table_attr = 'border="1"' if table_attr.empty?
    content.gsub!(/<simpletable.*?>/m, '')
    content.gsub!(/<\/simpletable>/m, '')
    content.strip!
    lines = content.split("\n")
    lines.collect! do |ln|
      ln.gsub!(/\t/, '  ')
      '<tr><td>' + ln.gsub(/  +/, '</td><td>') + '</td></tr>'
    end
    lines.collect! do |ln| ln.gsub(/<td>\s*?<\/td>/, '<td>&nbsp;</td>') end

    # if you do a .join("\n"), then the \n will be converted to <br>
    # ... so don't do that
    "<table #{table_attr}>\n#{lines.join('')}</table>"
  end
end

ClWiki::CustomFormatters.instance.register(FormatSimpleTable)
