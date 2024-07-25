# frozen_string_literal: true

require 'cgi'

module ClWiki
  class FormatPreBlockquote < ClWiki::CustomFormatter
    def self.match_re
      %r{\[p\].*?\[/p\]}mi
    end

    # Only matched text is passed in, and whatever is returned is used (i.e. you
    # don't have to use gsub! you're not modifying the page's) ivar of content.
    def self.format_content(content, page)
      content = CGI.escapeHTML(content)

      # Remove 0 or 1 newline at the front of the block, to remove the
      # almost-always-there first newline and prevent a gap always at the top of
      # every block, but allow additional newlines if the page really wants
      # newlines at the top of the block
      content.gsub!(/\[p\]\n?/i, '<blockquote><pre>')

      # Remove 0 to 2 newlines after the block, to remove unnecessary blank
      # lines in most cases, but keep 3 or more, to allow the page to
      # intentionally put some blank space after something if necessary.
      content.gsub!(%r{\[/p\]\n{0,2}}i, '</pre></blockquote>')
    end
  end
end

ClWiki::CustomFormatters.instance.register(ClWiki::FormatPreBlockquote)
