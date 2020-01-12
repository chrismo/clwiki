# frozen_string_literal: true
class FormatBlockquote < ClWiki::CustomFormatter
  def self.match_re
    %r{\[\].*\[/\]}m
  end

  def self.format_content(content, page)
    if content
      content.gsub!(/\[\]/, '<blockquote>')
      content.gsub!(%r{\[/\]}, '</blockquote>')
      content
    end
  end
end

ClWiki::CustomFormatters.instance.register(FormatBlockquote)
