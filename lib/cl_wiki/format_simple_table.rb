# frozen_string_literal: true

module ClWiki
  class FormatSimpleTable < ClWiki::CustomFormatter
    def self.match_re
      %r{<simpletable.*?>.*?</simpletable>}m
    end

    def self.format_content(content, page = nil)
      table_attr = content.scan(/<simpletable(.*?)>/m).to_s.strip
      table_attr = 'border="1"' if table_attr.empty?
      content.gsub!(/<simpletable.*?>/m, '')
      content.gsub!(%r{</simpletable>}m, '')
      content.strip!
      lines = content.split("\n")
      lines.collect! do |ln|
        ln.gsub!(/\t/, '  ')
        '<tr><td>' + ln.gsub(/  +/, '</td><td>') + '</td></tr>'
      end
      lines.collect! { |ln| ln.gsub(%r{<td>\s*?</td>}, '<td>&nbsp;</td>') }

      # if you do a .join("\n"), then the \n will be converted to <br>
      # ... so don't do that
      "<table #{table_attr}>\n#{lines.join('')}</table>"
    end
  end
end

ClWiki::CustomFormatters.instance.register(ClWiki::FormatSimpleTable)
