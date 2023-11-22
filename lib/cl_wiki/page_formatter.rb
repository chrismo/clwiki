module ClWiki
  class PageFormatter
    FIND_PAGE_NAME = 'Find'
    FIND_RESULTS_NAME = 'Find Results'

    attr_reader :full_name
    attr_accessor :content

    def initialize(content = nil, full_name = nil)
      @content = content
      self.full_name = full_name
      @wiki_index = nil
    end

    def full_name=(value)
      @full_name = value
      if @full_name
        @full_name = @full_name[1..-1] if @full_name[0..1] == '//'
      end
    end

    def header(full_page_name, page = nil)
      search_text = ::File.basename(full_page_name)
      page_path, page_name = ::File.split(full_page_name)
      page_path = '/' if page_path == '.'
      dirs = page_path.split('/')
      dirs = dirs[1..-1] if !dirs.empty? && dirs[0].empty?
      full_dirs = (0..dirs.length - 1).each { |i| full_dirs[i] = ('/' + dirs[0..i].join('/')) }
      head = String.new("<div class='wikiHeader'>")
      head << core_footer_links(full_page_name, -1).sub('wikiFooter', 'wikiFooter wikiFooterFloat')
      if [FIND_PAGE_NAME, FIND_RESULTS_NAME].include?(full_page_name)
        head << "<span class='pageName'>#{full_page_name}</span>"
      else
        head << "<span class='pageName'><a href='find?search_text=#{search_text}'>#{page_name}</a></span><br/>"
        full_dirs.each do |dir|
          head << "'<span class='pageTag'>'"
          head << "<a href=#{cgifn}?page=#{dir}>#{File.split(dir)[-1]}</a></span>"
        end
        head << '<br/>'
        head << "<span class='wikiPageData'>#{page_update_time(page)}</span><br/>" if page
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
      Dir["#{::File.dirname(__FILE__)}/footer/footer.*"].sort.each do |fn|
        require fn
      end

      ClWiki::CustomFooters.instance.process_footers(page)
    end

    def footer(page)
      return String.new unless page.is_a? ClWiki::Page
      custom_footer = process_custom_footers(page)
      custom_footer << core_footer_links(page.page_name)
    end

    def core_footer_links(wiki_name, tab_index = 0)
      # refactor string constants
      footer = String.new("<div class='wikiFooter'>")
      footer << '<ul>'
      if $wiki_conf.editable
        unless [FIND_PAGE_NAME, FIND_RESULTS_NAME].include?(wiki_name)
          footer << "<li><span class='wikiAction'><a href='#{wiki_name}/edit' tabindex=#{tab_index}>Edit</a></span></li>"
        end
      end
      footer << "<li><span class='wikiAction'><a href='find' tabindex=#{tab_index}>Find</a></span></li>"
      if $wiki_conf.publishTag
        footer << "<li><span class='wikiAction'><a href='recent' tabindex=#{tab_index}>Recent</a></span></li>"
      else
        footer << "<li><span class='wikiAction'><a href='FrontPage' tabindex=#{tab_index}>Home</a></span></li>"
      end
      footer << '</ul></div>'
      footer
    end

    def src_url
      "file://#{ClWiki::Page.read_file_full_path_and_name(@full_name)}"
    end

    def reload_url(with_global_edit_links = false)
      result = "#{full_url}?page=#{@full_name}"
      result << (with_global_edit_links ? '&globaledits=true' : '&globaledits=false')
    end

    def mailto_url
      "mailto:?Subject=wikifyi:%20#{@full_name}&Body=#{reload_url}"
    end

    def gsub_words
      @content.gsub(%r{<.+?>|</.+?>|\w+}) { |word| yield word }
    end

    def format_links
      no_wiki_link_in_effect = false
      inside_html_tags = false

      gsub_words do |word|
        if (word[0, 1] == '<') && (word[-1, 1] == '>')
          # refactor to class,local constant, instead of global
          if /<NoWikiLinks>/i.match?(word)
            no_wiki_link_in_effect = true
            word = ''
            # refactor to class,local constant, instead of global
          elsif /<\/NoWikiLinks>/i.match?(word)
            no_wiki_link_in_effect = false
            word = ''
          end

          if /<html>/i.match?(word)
            inside_html_tags = true
            word = ''
          elsif /<\/html>/i.match?(word)
            inside_html_tags = false
            word = ''
          end
        elsif is_wiki_name?(word)
          if !no_wiki_link_in_effect && !inside_html_tags
            # code smell here y'all
            word = convert_to_link(word) unless block_given?
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
      only_one_tag = /\A[^<]*<[^<>]*>[^>]*\z/
      header_tag_line = %r{\A\s*<h.>.*</h.>\s*\z}
      (str =~ only_one_tag) || (str =~ header_tag_line)
      # str.scan(/<.*>/).to_s == str.chomp
    end

    def starts_with_path_char(path)
      (path[0..0] == '/') || (path[0..1] == '//')
    end

    def cgifn
      $wiki_conf&.cgifn
    end

    def full_url
      ($wiki_conf.url_prefix + cgifn) if $wiki_conf
    end

    def convert_to_link(page_name)
      if ClWiki::Page.page_exists?(page_name)
        "<a href='#{page_name}'>#{page_name}</a>"
      else
        @wiki_index ||= ClWiki::MemoryIndexer.instance
        hits = @wiki_index.search(page_name, titles_only: true)

        result = case hits.length
                 when 0
                   page_name
                 when 1
                   "<a href='#{hits[0]}'>#{page_name}</a>"
                 else
                   "<a href='find?search_text=#{page_name}'>#{page_name}</a>"
                 end

        if $wiki_conf.editable && (hits.empty? || $wiki_conf.global_edits)
          result << "<a href='#{page_name}/edit'>?</a>"
        end
        result
      end
    end

    def is_wiki_name?(string)
      return false if string.empty?

      /\A[0-9]*[A-Z][a-z]\w*?[A-Z][a-z]\w*\z/.match?(string)
    end
  end
end
