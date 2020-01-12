# frozen_string_literal: true
require 'cgi'

class FormatPreBlockquote < ClWiki::CustomFormatter
  def self.match_re
    %r{\[p\].*?\[/p\]}mi
  end

  def self.format_content(content, page)
    content = CGI.escapeHTML(content)
    content.gsub!(/\[p\]/i, '<blockquote><pre>')
    content.gsub!(%r{\[/p\]}i, '</pre></blockquote>')
  end
end

ClWiki::CustomFormatters.instance.register(FormatPreBlockquote)
