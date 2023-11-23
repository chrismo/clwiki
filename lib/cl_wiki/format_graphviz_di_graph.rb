# frozen_string_literal: true

module ClWiki
  class FormatGraphVizDiGraph < ClWiki::CustomFormatter
    def self.match_re
      /digraph.*\}/m
    end

    def self.format_content(content, page)
      content.sub!(/digraph.*\}/m,
                   "<a href=\"dot.rb?fn=#{page.file_full_path_and_name}\">
                  <img src=\"dot.rb?fn=#{page.file_full_path_and_name}\">
                  </a>")
      content
    end
  end
end

ClWiki::CustomFormatters.instance.register(ClWiki::FormatGraphVizDiGraph)
