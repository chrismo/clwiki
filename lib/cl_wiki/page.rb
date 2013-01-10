require 'cgi'
require 'singleton'

require File.dirname(__FILE__) + '/file'
require File.dirname(__FILE__) + '/find_in_file'

$NO_WIKI_LINKS = "NoWikiLinks"
$NO_WIKI_LINKS_START = '<' + $NO_WIKI_LINKS + '>'
$NO_WIKI_LINKS_END = '</' + $NO_WIKI_LINKS + '>'

$HTML = "html"
$HTML_START = '<' + $HTML + '>'
$HTML_END = '</' + $HTML + '>'

$FIND_PAGE_NAME = "Find Page"
$FIND_RESULTS_NAME = "Find Results"

$DATE_TIME_FORMAT = "%a&nbsp;%b&nbsp;%d&nbsp;%Y %I:%M&nbsp;%p"

module ClWiki
  class Page
    attr_reader :content, :mtime, :name, :full_name, :pagePath, :raw_content,
                :fileFullPathAndName

    @@wikiIndexClient = nil

    #Refactor clwikifile out of here into a storage class that will
    # require in the appropriate storage file clwikifile, clwikisql

    # refactor away wikiPath ... should be taken care of elsewhere, otherwise
    # ClWiki must know it, and it should be storage independent
    def initialize(fullName, wiki_path=$wiki_path)
      @full_name = fullName
      raise 'fullName must start with /' if fullName[0..0] != '/'
      @wiki_path = wiki_path
      @wikiFile = ClWiki::File.new(@full_name, @wiki_path)
      @pagePath = @wikiFile.pagePath
      @name = @wikiFile.name
    end

    # <pre> text in 1.13.2 had extra line feeds, because the \n were xformed to
    # <br>\n, which results in two line feeds when rendered by Mozilla.
    # The change a few versions ago inside convert_newline_to_br which started
    # converting \n to <br>\n is the culprit here. I did this for more readable
    # html, but that does screw up <pre> sections, so it's put back now.
    def convert_newline_to_br
      newcontent = ""
      insideHtmlTags = false
      @content.each_line do |substr|
        insideHtmlTags = true if (substr =~ /#{$HTML_START}/)
        insideHtmlTags = false if (substr =~ /#{$HTML_END}/)
        if ((!ClWiki::PageFormatter.only_html(substr)) or (substr == "\n")) and !insideHtmlTags
          newcontent = newcontent + substr.gsub(/\n/, "<br>")
        else
          newcontent = newcontent + substr
        end
      end
      @content = newcontent
    end

    def self.wikiIndexClient
      @@wikiIndexClient = ClWikiIndexClient.new if !@@wikiIndexClient
      @@wikiIndexClient
    end

    def read_raw_content
      @raw_content = @wikiFile.content.join.gsub(/\r\n/, "\n")
      read_page_attributes
      ClWiki::Page.wikiIndexClient.add_hit(@full_name) if $wiki_conf.access_log_index
    end

    def content_never_edited?
      @wikiFile.content_is_default?
    end

    def delete
      @wikiFile.delete
    end

    def self.read_file_full_path_and_name(full_name, wiki_path=$wiki_path)
      wiki_file = ClWikiFile.new(full_name, wiki_path, $wikiPageExt, false)
      wiki_file.fullPathAndName
    end

    def read_page_attributes
      wikiFile = @wikiFile # ClWikiFile.new(@fullName, @wikiPath)
      @mtime = wikiFile.modTimeAtLastRead
      @fileFullPathAndName = wikiFile.fullPathAndName
    end

    def read_raw_content_with_forwarding(full_page_name)
      stack = []
      history = []
      content = ''
      final_page_name = full_page_name
      stack.push(full_page_name)
      while !stack.empty?
        this_pg_name = stack.pop
        if history.index(this_pg_name)
          pg_content = '-= CIRCULAR FORWARDING DETECTED =-'
        else
          pg = ClWiki::Page.new(this_pg_name)
          pg.read_raw_content
          pg_content = pg.raw_content
          fwd_full_page_name = get_forward_ref(pg_content)
          if fwd_full_page_name
            pg_content = "Auto forwarded from /" + this_pg_name + "<hr>" + "/" + fwd_full_page_name + ":\n\n"
            stack.push fwd_full_page_name
          else
            final_page_name = this_pg_name
          end
        end
        content << pg_content << "\n"
        history << this_pg_name
      end
      [content, final_page_name]
    end

    def read_content(includeHeaderAndFooter=true, include_diff=false)
      read_page_attributes
      @content, final_page_name = read_raw_content_with_forwarding(@full_name)
      process_custom_renderers
      convert_newline_to_br
      f = ClWiki::PageFormatter.new(content, final_page_name)
      @content = f.formatLinks
      if includeHeaderAndFooter
        @content = get_header + @content + get_footer
      end
      @content = CLabs::WikiDiffFormatter.format_diff(@wikiFile.diff) + @content if include_diff
      @content
    end

    def process_custom_renderers
      Dir['format/format.*'].each do |fn|
        require fn
      end

      ClWiki::CustomFormatters.instance.process_formatters(@content, self)
    end

    def get_header
      f = ClWiki::PageFormatter.new(nil, @full_name)
      f.header(@full_name)
    end

    def get_footer
      f = ClWiki::PageFormatter.new(nil, @full_name)
      f.footer(self)
    end

    def get_forward_ref(content)
      content_ary = content.split("\n")
      res = (content_ary.collect { |ln|
        if ln.strip.empty?;
          nil;
        else
          ln;
        end }.compact.length == 1)
      if res
        res = content_ary[0] =~ /^see (.*)/i
      end

      if res
        page_name = $1
        f = ClWiki::PageFormatter.new(content, @full_name)
        page_name = f.expand_path(page_name, @full_name)
        res = f.is_wiki_name?(page_name)
        if res
          res = ClWiki::Page.page_exists?(page_name)
        end
      end
      if res
        page_name
      else
        nil
      end
    end

    def update_content(newcontent, mtime)
      wikiFile = @wikiFile # ClWikiFile.new(@fullName, @wikiPath)
      wikiFile.clientLastReadModTime = mtime
      wikiFile.content = newcontent
      if $wiki_conf.useIndex != ClWiki::Configuration::USE_INDEX_NO
        wikiIndexClient = ClWiki::IndexClient.new
        wikiIndexClient.reindex_page(@full_name)
      end
    end

    def self.page_exists?(fullPageName)
      if ($wiki_conf.useIndex != ClWiki::Configuration::USE_INDEX_NO) &&
          ($wiki_conf.useIndexForPageExists)
        res = ClWiki::Page.wikiIndexClient.page_exists?(fullPageName)
      else
        wikiFile = ClWiki::File.new(fullPageName, $wiki_path, $wikiPageExt, false)
        res = wikiFile.file_exists?
      end
      res
    end
  end

  class PageFormatter
    attr_accessor :content

    def initialize(content=nil, aFullName=nil)
      @content = content
      self.fullName = aFullName
      @wikiIndex = nil
    end

    def fullName=(value)
      @full_name = value
      if @full_name
        @full_name = @full_name[1..-1] if @full_name[0..1] == '//'
      end
    end

    def fullName
      @full_name
    end

    def header(fullPageName, searchText = '')
      searchText = ::File.basename(fullPageName) if searchText == ''
      pagePath, pageName = ::File.split(fullPageName)
      pagePath = '/' if pagePath == '.'
      dirs = pagePath.split('/')
      dirs = dirs[1..-1] if !dirs.empty? && dirs[0].empty?
      fulldirs = []
      (0..dirs.length-1).each { |i| fulldirs[i] = ('/' + dirs[0..i].join('/')) }
      if (fullPageName != $FIND_PAGE_NAME) and
          (fullPageName != $FIND_RESULTS_NAME) and
          (fullPageName != $wiki_conf.recent_changes_name) and
          (fullPageName != $wiki_conf.stats_name)
        head = "<span class='pageName'><a href=#{cgifn}?find=true&searchText=#{searchText}&type=full>#{pageName}</a></span><br><br>"
        fulldirs.each do |dir|
          head << "<span class='pageTag'>"
          head << "<a href=#{cgifn}?page=#{dir}>#{File.split(dir)[-1]}</a></span>"
        end
        head << "<br>"
      else
        "<span class='pageName'>" + fullPageName + "</span>"
      end
    end

    def process_custom_footers(page)
      Dir[::File.dirname(__FILE__) + '/footer/footer.*'].each do |fn|
        require fn
      end

      ClWiki::CustomFooters.instance.process_footers(page)
    end

    def footer(page)
      return '' if !page.is_a? ClWiki::Page # blogki does this

      custom_footer = process_custom_footers(page)

      wikiName, modTime = page.full_name, page.mtime
      if modTime
        update = 'last update: ' + modTime.strftime($DATE_TIME_FORMAT)
      else
        update = ''
      end

      if (wikiName != $FIND_PAGE_NAME) and
          (wikiName != $FIND_RESULTS_NAME) and
          (wikiName != $wiki_conf.recent_changes_name) and
          (wikiName != $wiki_conf.stats_name)
        if $wiki_conf.enable_cvs
          update = "<a href=#{cgifn}?page=" + wikiName + "&diff=true>diff</a> | " + update
        end
      end

      # refactor string constants
      footer = ""
      footer << "<ul>"
      if (wikiName != $FIND_PAGE_NAME) and
          (wikiName != $FIND_RESULTS_NAME) and
          (wikiName != $wiki_conf.recent_changes_name) and
          (wikiName != $wiki_conf.stats_name)
        if $wiki_conf.editable
          footer << ("<li><span class='wikiAction'><a href=#{cgifn}?page=" + wikiName + "&edit=true>Edit</a></span></li>")
        end
      end
      footer << "<li><span class='wikiAction'><a href=#{cgifn}?find=true>Find</a></span></li>"
      footer << "<li><span class='wikiAction'><a href=#{cgifn}?recent=true>Recent</a></span></li>"
      footer << "<li><span class='wikiAction'><a href=#{cgifn}?about=true>About</a></span></li>" if wikiName == "/FrontPage"
      footer << "<li><span class='wikiPageData'>#{update}</span></li>"
      footer << "</ul>"
      return custom_footer << footer
    end

    def src_url
      "file://#{ClWiki::Page.read_file_full_path_and_name(@full_name)}"
    end

    def reload_url(with_global_edit_links=false)
      result = "#{full_url}?page=#{@full_name}"
      if with_global_edit_links
        result << "&globaledits=true"
      else
        result << "&globaledits=false"
      end
    end

    def mailto_url
      "mailto:?Subject=wikifyi:%20#{@full_name}&Body=#{reload_url}"
    end

    def gsubWords
      @content.gsub(/<.+?>|<\/.+?>|[\w\\\/]+/) { |word| yield word }
    end

    def convert_relative_wikinames_to_absolute
      # do not go ahead without testing here
      #formatLinks do |word|
      #  if isWikiName?(word)
      #end

      # problem here is we should obey the NoWikiLinks and Html tag rules,
      # and those variables aren't being yielded right now. If we change
      # how the yield works, it affects the indexer. And we can't just
      # tack on additional yield params and have existing code that only
      # pays attention to the first keep working:
      #
      # irb(main):001:0> def test
      # irb(main):002:1>   yield 1,2,3
      # irb(main):003:1> end
      # nil
      # irb(main):004:0> test do |a|
      # irb(main):005:1* puts a
      # irb(main):006:1> end
      # 1
      # 2
      # 3
    end

    def formatLinks
      noWikiLinkInEffect = false
      insideHtmlTags = false

      gsubWords do |word|
        if (word[0, 1] == '<') and (word[-1, 1] == '>')
          # refactor to class,local constant, instead of global
          if (word =~ /#{$NO_WIKI_LINKS_START}/i)
            noWikiLinkInEffect = true
            word = ''
            # refactor to class,local constant, instead of global
          elsif (word =~ /#{$NO_WIKI_LINKS_END}/i)
            noWikiLinkInEffect = false
            word = ''
          end

          if (word =~ /#{$HTML_START}/i)
            insideHtmlTags = true
            word = ''
          elsif (word =~ /#{$HTML_END}/i)
            insideHtmlTags = false
            word = ''
          end
        elsif is_wiki_name?(word)
          if !noWikiLinkInEffect and !insideHtmlTags
            # code smell here y'all
            word = convertToLink(word) if !block_given?
          end
        end
        if block_given?
          yield word
        else
          word
        end
      end
    end

    def self.only_html(str)
      onlyOneTag = /\A[^<]*<[^<>]*>[^>]*\z/
      headerTagLine = /\A\s*<h.>.*<\/h.>\s*\z/
      (str =~ onlyOneTag) || (str =~ headerTagLine)
      # str.scan(/<.*>/).to_s == str.chomp
    end

    def starts_with_path_char(path)
      (path[0..0] == '/') || (path[0..1] == '//')
    end

    def do_file_expand_path(partial, reference)
      # expand_path works differently on Windows/*nix, so we have to force
      # path separators to be forward slash for consistency
      partial.gsub!(/\\/, '/')
      reference.gsub!(/\\/, '/')
      res = ::File.expand_path(partial, reference)

      # 1.6.8 did not put on the drive letter at the front of the path. 1.8
      # does, so we need to strip it off, because we're not really looking
      # for file system pathing here.
      res = res[2..-1] if res[0..1] =~ /.:/

      res
    end

    def expand_path(partial, reference)
      if !starts_with_path_char(partial)
        # sibling
        # "" is in [0] if partial is an absolute
        partial_pieces = partial.split('/').delete_if { |p| p == "" }
        match_found = false
        result = ''
        (partial_pieces.length-1).downto(0) do |i|
          this_partial = '/' + partial_pieces[0..i].join('/')
          match_loc = (reference.rindex(/#{this_partial}/))
          if match_loc
            match_found = true
            # isn't next line stored in a Regexp globals? pre-match and match, right?
            result = reference[0..(match_loc + this_partial.length-1)]
            partial_remainder = partial_pieces[(i+1)..-1]
            result = ::File.join(result, partial_remainder)
            result.chop! if result[-1..-1] == '/'
            break
          end
        end
        unless match_found
          # take off last entry on reference path to force a sibling
          # or refactor elsewhere to pass nothing but paths into this
          # method.
          reference, = ::File.split(reference)
          result = do_file_expand_path(partial, (reference.empty? ? '/' : reference))
        end
      else
        # to get File.expand_path to do what I need:
        #   change // to /
        #   change /  to ./
        if partial[0..1] == '//'
          partial = partial[1..-1]
        else
          partial = '.' + partial
        end
        result = do_file_expand_path(partial, reference)
      end

      # if ('/a/b', '/') passed, then '//' ends up at front because
      # this is not illegal at the very first in File.expand_path
      result = result[1..-1] if result[0..1] == '//'
      result
    end

    def do_fullparts_displayparts_assertion(fullparts, displayparts)
      # this is complicated, unfortunately. expand_path does not ever return
      # // at the front of an absolute path, though it should. I can't change
      # it right now cuz that's a major change.

      # in the case where the display name is absolute with //, the full
      # name will only have one slash up front, so we need to tweak that case
      # temporarily to get this assertion to work

      # we also need to eliminate slash positions, which shows as empty
      # strings in these arrays
      afullparts = fullparts.dup
      afullparts.delete_if do |part|
        part.empty?
      end

      adispparts = displayparts.dup
      adispparts.delete_if do |part|
        part.empty?
      end

      if afullparts[(-adispparts.length)..-1] != adispparts
        raise "assertion failed. displayparts <#{adispparts.inspect}> should be " +
                  "tail end of fullparts <#{afullparts.inspect}>"
      end
    end

    def format_for_dir_and_page_links(pageFullName, pageName)
      fullparts = pageFullName.split('/')
      displayparts = pageName.split('/')
      do_fullparts_displayparts_assertion(fullparts, displayparts)
      result = ''
      displayparts.each do |part|
        if !part.empty?
          fullpagelink = fullparts[0..fullparts.index(part)].join('/')
          result << '/' if !result.empty? && result[-1..-1] != '/'
          result << "<a href=#{cgifn}?page=#{fullpagelink}>#{part}</a>"
        else
          result << '/'
        end
      end
      result
    end

    def cgifn
      $wiki_conf.cgifn if $wiki_conf
    end

    def full_url
      ($wiki_conf.url_prefix + cgifn) if $wiki_conf
    end

    def convertToLink(pageName)
      # We need to calculate its fullPageName based on the ref fullName in case
      # the pageName is a relative reference
      pageFullName = expand_path(pageName, @full_name)
      if ClWiki::Page.page_exists?(pageFullName)
        format_for_dir_and_page_links(pageFullName, pageName)
      else
        if $wiki_conf.useIndex == ClWiki::Configuration::USE_INDEX_NO
          finder = FindInFile.new($wiki_path)
          finder.find(pageName, FindInFile::FILE_NAME_ONLY)
          hits = finder.files.collect { |f| f.sub($wikiPageExt, '') }
        else
          @wikiIndex = ClWiki::IndexClient.new if @wikiIndex.nil?
          titles_only = true
          hits = @wikiIndex.search(pageName, titles_only)
          hits = GlobalHitReducer.reduce_to_exact_if_exists(pageName, hits)
        end

        case hits.length
          when 0
            result = pageName
          when 1
            result = "<a href=#{cgifn}?page=#{hits[0]}>#{pageName}</a>"
          else
            result = "<a href=#{cgifn}?find=true&searchText=#{pageName}&type=title>#{pageName}</a>"
        end

        if ($wiki_conf.editable) && ((hits.length == 0) || ($wiki_conf.global_edits))
          result << "<a href=#{cgifn}?page=" + pageFullName + "&edit=true>?</a>"
        end
        result
      end
    end

    def is_wiki_name?(string)
      all_wiki_names = true
      names = string.split(/[\\\/]/)

      # if first character is a slash, then split puts an empty string into names[0]
      names.delete_if { |name| name.empty? }
      all_wiki_names = false if names.empty?
      names.each do |name|
        all_wiki_names =
            (
            all_wiki_names and

                # the number of all capitals followed by a lowercase is greater than 1
                (name.scan(/[A-Z][a-z]/).length > 1) and

                # the first letter is capitalized or slash
                (
                (name[0, 1] == name[0, 1].capitalize) or (name[0, 1] == '/') or (name[0, 1] == "\\")
                ) and

                # there are no non-word characters in the string (count is 0)
                # ^[\w|\\|\/] is read:
                # _____________[_____  _^_  ____\w_________  _|  __\\______  _|  ___\/________]
                # characters that are  not  word characters  or  back-slash  or  forward-slash
                # (the not negates the *whole* character set (stuff in brackets))
                (name.scan(/[^\w\\\/]/).length == 0)
            )
      end
      return all_wiki_names
    end
  end
  class CustomFooters
    include Singleton

    def register(class_ref)
      @footers ||= []
      @footers << class_ref
    end

    def process_footers(page)
      content = ''
      @footers.each do |f|
        content << f.footer_html(page)
      end if @footers
      return content
    end
  end

  # to create your own custom footer, see any of the files in the ./footer
  # directory and imitate.
  class CustomFooter
  end

  class CustomFormatters
    include Singleton

    def register(class_ref)
      @formatters ||= []
      @formatters << class_ref
    end

    def process_formatters(content, page)
      @formatters.each do |f|
        if content =~ f.match_re
          content.gsub!(f.match_re) { |match| f.format_content(match, page) }
        end
      end if @formatters
    end
  end

  # to create your own custom formatter, see any of the files in the ./format
  # directory and imitate.
  class CustomFormatter
  end

  class GlobalHitReducer
    def GlobalHitReducer.reduce_to_exact_if_exists(term, hits)
      reduced = hits.dup
      reduced.delete_if do |hit|
        parts = hit.split('/')
        exact = (parts[-1] =~ /^#{term}$/i)
        !exact
      end

      if !reduced.empty?
        reduced
      else
        hits
      end
    end
  end
end

module CLabs
  class WikiDiffFormatter
    def WikiDiffFormatter.format_diff(diff)
      "<b>Diff</b><br><pre>\n#{CGI.escapeHTML(diff)}\n</pre><br><hr=width\"50%\">"
    end
  end
end
