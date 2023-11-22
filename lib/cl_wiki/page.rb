# frozen_string_literal: true

require 'cgi'
require 'singleton'

module ClWiki
  class Page
    attr_reader :content, :mtime, :name, :page_name, :raw_content,
      :file_full_path_and_name

    def initialize(page_name, wiki_path: $wiki_conf.wiki_path, owner: PublicUser.new)
      raise "Fix this - no slashes! #{page_name}" if %r{/}.match?(page_name)

      @page_name = page_name
      @wiki_path = wiki_path
      @owner = owner
      @wiki_file = ClWiki::File.new(@page_name, @wiki_path, owner: @owner)
      @name = @wiki_file.name
    end

    def convert_newline_to_br
      new_content = ''
      inside_html_tags = false
      @content.each_line do |substr|
        inside_html_tags = true if /<html>/.match?(substr)
        inside_html_tags = false if /<\/html>/.match?(substr)
        new_content += if (!ClWiki::PageFormatter.only_html(substr) || (substr == "\n")) && !inside_html_tags
                         substr.gsub(/\n/, '<br>')
                       else
                         substr
                       end
      end
      @content = new_content
    end

    def is_new?
      @wiki_file.has_default_content?
    end

    def read_raw_content
      @raw_content = @wiki_file.content
      read_page_attributes
    end

    def delete
      @wiki_file.delete
    end

    def read_page_attributes
      wiki_file = @wiki_file
      @mtime = wiki_file.mod_time_at_last_read

      # TODO: kill this - not needed except in graphviz renderer?
      @file_full_path_and_name = wiki_file.full_path_and_name
    end

    def content_encrypted?
      @wiki_file.content_encrypted?
    end

    def read_raw_content_with_forwarding(full_page_name)
      stack = []
      history = []
      content = String.new
      final_page_name = full_page_name
      stack.push(full_page_name)
      until stack.empty?
        this_pg_name = stack.pop
        if history.index(this_pg_name)
          pg_content = '-= CIRCULAR FORWARDING DETECTED =-'
        else
          pg = ClWiki::Page.new(this_pg_name, owner: @owner)
          pg.read_raw_content
          pg_content = pg.raw_content
          fwd_full_page_name = get_forward_ref(pg_content)
          if fwd_full_page_name
            pg_content = "Auto forwarded from #{this_pg_name}<br><br>#{fwd_full_page_name}<br><br>"
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

    def read_content(include_header_and_footer = true, include_diff = false)
      read_page_attributes
      @content, final_page_name = read_raw_content_with_forwarding(@page_name)
      process_custom_renderers
      convert_newline_to_br
      f = ClWiki::PageFormatter.new(@content, final_page_name)
      @content = "<div class='wikiBody'>#{f.format_links}</div>"
      @content = get_header + @content + get_footer if include_header_and_footer
      @content = CLabs::WikiDiffFormatter.format_diff(@wiki_file.diff) + @content if include_diff
      @content
    end

    def process_custom_renderers
      root_dirs = [::File.join(::File.dirname(__FILE__), 'format')] + $wiki_conf.custom_formatter_load_path
      root_dirs.each do |root_dir|
        Dir[::File.join(root_dir, 'format.*')].sort.each do |fn|
          require fn
        end
      end

      ClWiki::CustomFormatters.instance.process_formatters(@content, self)
    end

    def get_header
      ClWiki::PageFormatter.new(nil, @page_name).header(@page_name, self)
    end

    def get_footer
      ClWiki::PageFormatter.new(nil, @page_name).footer(self)
    end

    def get_forward_ref(content)
      content_ary = content.split("\n")
      res = (content_ary.collect { |ln| ln.strip.empty? ? nil : ln }.compact.length == 1)
      res = content_ary[0] =~ /^see (.*)/i if res

      if res
        page_name = Regexp.last_match(1)
        f = ClWiki::PageFormatter.new(content, @page_name)
        res = f.is_wiki_name?(page_name)
        res = ClWiki::Page.page_exists?(page_name) if res
      end
      page_name if res
    end

    def update_content(new_content, mtime, encrypt = false)
      @wiki_file.client_last_read_mod_time = mtime
      encrypt ? @wiki_file.encrypt_content! : @wiki_file.do_not_encrypt_content!
      @wiki_file.content = new_content
      ClWiki::MemoryIndexer.instance(page_owner: @owner).reindex_page(@page_name)
    end

    # TODO: if this is the 1st time the index is instantiated, it won't have owner.
    # and this will blow up waaay down the stack as it tries to do all of the indexing
    # without an owner.
    #
    # For this query, however, it doesn't need owner, since it's just looking for
    # existence. Hmmm. The index could be lazy-loaded, with names and metadata
    # first, and not content if owner doesn't match. But ... I dunno.
    def self.page_exists?(page_name)
      ClWiki::MemoryIndexer.instance.page_exists?(page_name)
    end
  end
end
