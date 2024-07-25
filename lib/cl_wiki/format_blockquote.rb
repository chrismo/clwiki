# frozen_string_literal: true

module ClWiki
  class FormatBlockquote < ClWiki::CustomFormatter
    def self.match_re
      %r{\[\].*\[/\]}m
    end

    def self.format_content(content, page)
      if content
        # I wanted to bring this in, similar to my last change to
        # format_pre_blockquote.rb. But somehow this is impacting how
        # @content.each_line works in convert_newline_to_br leading to
        # unexpected results there. I can't figure it out right now and this
        # isn't that important, so I'm not going to do it right now.

        # Remove 0 or 1 newline at the front of the block
        # content.gsub!(/\[\]\n?/, '<blockquote>')

        # Remove 0 to 2 newlines after the block to keep things tidy.
        # content.gsub!(%r{\[/\]\n{0,2}}, '</blockquote>')

        content.gsub!(/\[\]/, '<blockquote>')
        content.gsub!(%r{\[/\]}, '</blockquote>')

        content
      end
    end
  end
end

ClWiki::CustomFormatters.instance.register(ClWiki::FormatBlockquote)
