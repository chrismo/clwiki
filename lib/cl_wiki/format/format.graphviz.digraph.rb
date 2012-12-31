class FormatGraphVizDiGraph < ClWikiCustomFormatter
  def FormatGraphVizDiGraph.match_re
    /digraph.*\}/m
  end
  
  def FormatGraphVizDiGraph.format_content(content, page)
    content.sub!(/digraph.*\}/m,
      '<a href="dot.rb?fn=' + page.fileFullPathAndName + '">' +
      '<img src="dot.rb?fn=' + page.fileFullPathAndName + '">' +
      '</a>'
    )
    content
  end
end

ClWikiCustomFormatters.instance.register(FormatGraphVizDiGraph)
