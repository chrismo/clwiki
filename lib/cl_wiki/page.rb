require 'cgi'
require 'singleton'

require File.expand_path('file', __dir__)
require File.expand_path('find_in_file', __dir__)

$FIND_PAGE_NAME = "Find"
$FIND_RESULTS_NAME = "Find Results"

module ClWiki
  class Page
    attr_reader :content, :mtime, :name, :full_name, :pagePath, :raw_content,
                :file_full_path_and_name

    @@wikiIndexClient = nil

    def initialize(fullName, wiki_path=$wiki_path)
      @full_name = fullName
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
      new_content = ""
      insideHtmlTags = false
      @content.each_line do |substr|
        insideHtmlTags = true if (substr =~ /#{'<html>'}/)
        insideHtmlTags = false if (substr =~ /#{'</html>'}/)
        if ((!ClWiki::PageFormatter.only_html(substr)) or (substr == "\n")) and !insideHtmlTags
          new_content = new_content + substr.gsub(/\n/, "<br>")
        else
          new_content = new_content + substr
        end
      end
      @content = new_content
    end

    def read_raw_content
      @raw_content = @wikiFile.content.join.gsub(/\r\n/, "\n")
      read_page_attributes
      ClWiki::IndexClient.new.add_hit(@full_name) if $wiki_conf.access_log_index
    end

    # TODO: consider removing
    def content_never_edited?
      @wikiFile.content_is_default?
    end

    def delete
      @wikiFile.delete
    end

    def read_page_attributes
      wiki_file = @wikiFile # ClWikiFile.new(@fullName, @wikiPath)
      @mtime = wiki_file.mod_time_at_last_read
      @file_full_path_and_name = wiki_file.fullPathAndName
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
            pg_content = "Auto forwarded from #{this_pg_name.strip_slash_prefix}<br><br>#{fwd_full_page_name}<br><br>"
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

    def read_content(include_header_and_footer=true, include_diff=false)
      read_page_attributes
      @content, final_page_name = read_raw_content_with_forwarding(@full_name)
      process_custom_renderers
      convert_newline_to_br
      f = ClWiki::PageFormatter.new(@content, final_page_name)
      @content = "<div class='wikiBody'>#{f.formatLinks}</div>"
      if include_header_and_footer
        @content = get_header + @content + get_footer
      end
      @content = CLabs::WikiDiffFormatter.format_diff(@wikiFile.diff) + @content if include_diff
      @content
    end

    def process_custom_renderers
      root_dirs = [::File.join(::File.dirname(__FILE__), 'format')] + $wiki_conf.custom_formatter_load_path
      root_dirs.each do |root_dir|
        Dir[::File.join(root_dir, 'format.*')].each do |fn|
          require fn
        end
      end

      ClWiki::CustomFormatters.instance.process_formatters(@content, self)
    end

    def get_header
      f = ClWiki::PageFormatter.new(nil, @full_name)
      f.header(@full_name, self)
    end

    def get_footer
      f = ClWiki::PageFormatter.new(nil, @full_name)
      f.footer(self)
    end

    def get_forward_ref(content)
      content_ary = content.split("\n")
      res = (content_ary.collect { |ln| ln.strip.empty? ? nil : ln }.compact.length == 1)
      if res
        res = content_ary[0] =~ /^see (.*)/i
      end

      if res
        page_name = $1
        f = ClWiki::PageFormatter.new(content, @full_name)
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

    def update_content(new_content, mtime)
      wiki_file = @wikiFile # ClWikiFile.new(@fullName, @wikiPath)
      wiki_file.clientLastReadModTime = mtime
      wiki_file.content = new_content
      if $wiki_conf.useIndex != ClWiki::Configuration::USE_INDEX_NO
        wiki_index_client = ClWiki::IndexClient.new
        wiki_index_client.reindex_page_and_save_async(@full_name)
      end
    end

    def self.page_exists?(page_name)
      if ($wiki_conf.useIndex != ClWiki::Configuration::USE_INDEX_NO) &&
          ($wiki_conf.useIndexForPageExists)
        res = ClWiki::IndexClient.new.page_exists?(page_name)
      else
        wiki_file = ClWiki::File.new(page_name, $wiki_path, ClWiki::FILE_EXT, false)
        res = wiki_file.file_exists?
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

    def header(full_page_name, page = nil)
      search_text = ::File.basename(full_page_name)
      page_path, page_name = ::File.split(full_page_name)
      page_path = '/' if page_path == '.'
      dirs = page_path.split('/')
      dirs = dirs[1..-1] if !dirs.empty? && dirs[0].empty?
      full_dirs = (0..dirs.length-1).each { |i| full_dirs[i] = ('/' + dirs[0..i].join('/')) }
      head = '<div class=\'wikiHeader\'>'
      if (full_page_name != $FIND_PAGE_NAME) and
          (full_page_name != $FIND_RESULTS_NAME) and
          (full_page_name != $wiki_conf.recent_changes_name) and
          (full_page_name != $wiki_conf.stats_name)
        head << "<span class='pageName'><a href='find?search_text=#{search_text}'>#{page_name}</a></span><br/>"
        full_dirs.each do |dir|
          head << '<span class=\'pageTag\'>'
          head << "<a href=#{cgifn}?page=#{dir}>#{File.split(dir)[-1]}</a></span>"
        end
        head << '<br/>'
        head << "<span class='wikiPageData'>#{page_update_time(page)}</span><br/>" if page
      else
        head << '<span class=\'pageName\'>' + full_page_name + '</span>'
      end
      head << '</div>'
    end

    def page_update_time(page)
      mod_time = page.mtime
      if mod_time
        update_format = $wiki_conf.page_update_format.gsub(/ /, '&nbsp;')
        mod_time.strftime(update_format)
      else
        ''
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

      wiki_name = page.full_name

      # refactor string constants
      footer = "<div class='wikiFooter'>"
      footer << "<ul>"
      if (wiki_name != $FIND_PAGE_NAME) and
          (wiki_name != $FIND_RESULTS_NAME) and
          (wiki_name != $wiki_conf.recent_changes_name) and
          (wiki_name != $wiki_conf.stats_name)
        if $wiki_conf.editable
          footer << ("<li><span class='wikiAction'><a href='" + wiki_name.strip_slash_prefix + "/edit'>Edit</a></span></li>")
        end
      end
      footer << "<li><span class='wikiAction'><a href='find'>Find</a></span></li>"
      footer << "<li><span class='wikiAction'><a href='recent'>Recent</a></span></li>"
      # footer << "<li><span class='wikiAction'><a href=#{cgifn}?about=true>About</a></span></li>" if wiki_name == "/FrontPage"
      footer << "</ul></div>"
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
      @content.gsub(/<.+?>|<\/.+?>|\w+/) { |word| yield word }
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
      no_wiki_link_in_effect = false
      inside_html_tags = false

      gsubWords do |word|
        if (word[0, 1] == '<') and (word[-1, 1] == '>')
          # refactor to class,local constant, instead of global
          if word =~ /#{'<NoWikiLinks>'}/i
            no_wiki_link_in_effect = true
            word = ''
            # refactor to class,local constant, instead of global
          elsif word =~ /#{'</NoWikiLinks>'}/i
            no_wiki_link_in_effect = false
            word = ''
          end

          if word =~ /#{'<html>'}/i
            inside_html_tags = true
            word = ''
          elsif word =~ /#{'</html>'}/i
            inside_html_tags = false
            word = ''
          end
        elsif is_wiki_name?(word)
          if !no_wiki_link_in_effect and !inside_html_tags
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

    def cgifn
      $wiki_conf.cgifn if $wiki_conf
    end

    def full_url
      ($wiki_conf.url_prefix + cgifn) if $wiki_conf
    end

    def convertToLink(page_name)
      if ClWiki::Page.page_exists?(page_name)
        "<a href='#{page_name.strip_slash_prefix}'>#{page_name.strip_slash_prefix}</a>"
      else
        if $wiki_conf.useIndex == ClWiki::Configuration::USE_INDEX_NO
          finder = FindInFile.new($wiki_path)
          finder.find(page_name, FindInFile::FILE_NAME_ONLY)
          hits = finder.files.collect { |f| f.sub(ClWiki::FILE_EXT, '') }
        else
          @wikiIndex = ClWiki::IndexClient.new if @wikiIndex.nil?
          titles_only = true
          hits = @wikiIndex.search(page_name, titles_only)
          hits = GlobalHitReducer.reduce_to_exact_if_exists(page_name, hits)
        end

        case hits.length
          when 0
            result = page_name
          when 1
            result = "<a href='#{hits[0]}'>#{page_name}</a>"
          else
            result = "<a href='find?search_text=#{page_name}'>#{page_name}</a>"
        end

        if ($wiki_conf.editable) && ((hits.length == 0) || ($wiki_conf.global_edits))
          result << "<a href='#{page_name}/edit'>?</a>"
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

    def unregister(class_ref)
      @formatters.delete(class_ref)
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

class String
  def ensure_slash_prefix
    self[0..0] != '/' ? "/#{self}" : self
  end

  def strip_slash_prefix
    self.gsub(/^\//, '')
  end
end
