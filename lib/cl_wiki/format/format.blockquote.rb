class FormatBlockquote < ClWikiCustomFormatter
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

ClWikiCustomFormatters.instance.register(FormatBlockquote)
