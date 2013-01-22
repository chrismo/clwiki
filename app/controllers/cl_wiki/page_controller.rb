require 'cl_wiki/page'

module ClWiki
  class PageController < ApplicationController
    before_filter :redirect_legacy_cgi_urls
    before_filter :initialize_formatter
    before_filter :front_page_if_bad_name

    def show
      @page = ClWiki::Page.new(@page_name)
      @page.read_content
      @page
    end

    def edit
      @page = ClWiki::Page.new(@page_name)
      @page.read_raw_content
      @page
    end

    def update
      @page = ClWiki::Page.new(@page_name)
      @page.update_content(params[:page_content], Time.at(params[:client_mod_time].to_s.to_i))
      redirect_to params[:save_and_edit] ? page_edit_url(:page_name => @page.full_name.strip_slash_prefix) : page_show_url(:page_name => @page.full_name.strip_slash_prefix)
    end

    def find
      @formatter = ClWiki::PageFormatter.new
      @search_text = params[:search_text]
      @results = []
      if @search_text
        hits = search(@search_text)

        hits.each do |full_name|
          @formatter.fullName = full_name
          @results << "#{@formatter.convertToLink(full_name)}"
        end
      end
    end

    def search(text)
      case $wiki_conf.useIndex
        when ClWiki::Configuration::USE_INDEX_NO
          finder = FindInFile.new($wiki_path)
          finder.find(text)
          finder.files.collect do |filename|
            filename.sub($wikiPageExt, '')
          end
        else
          ClWiki::IndexClient.new.search(text)
      end
    end

    def front_page_name
      '/FrontPage'
    end

    def redirect_legacy_cgi_urls
      if request.fullpath.start_with?(legacy_path)
        page_name = params[:page].split('/')[-1]
        case
          when request.query_parameters.include?('edit')
            redirect_to page_edit_url(:page_name => page_name)
          else
            redirect_to page_show_url(:page_name => page_name)
        end
      end
    end

    def front_page_if_bad_name
      page_name = params[:page_name]
      @page_name = if (page_name.blank?) || (!@formatter.is_wiki_name?(page_name))
                     front_page_name
                   elsif !$wiki_conf.editable && !ClWiki::Page.page_exists?(page_name.ensure_slash_prefix)
                     front_page_name
                   else
                     page_name
                   end
      @page_name = @page_name.ensure_slash_prefix
    end

    def initialize_formatter
      @formatter = ClWiki::PageFormatter.new
    end
  end
end
