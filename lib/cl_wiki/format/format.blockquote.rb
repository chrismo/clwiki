class FormatBlockquote < ClWiki::CustomFormatter
  def FormatBlockquote.match_re
    /\[\].*\[\/\]/m
  end
  
  def FormatBlockquote.format_content(content, page)
    if content
      content.gsub!(/\[\]/, "<blockquote>")
      content.gsub!(/\[\/\]/, "</blockquote>")
      content
    end
  end
end

ClWiki::CustomFormatters.instance.register(FormatBlockquote)
