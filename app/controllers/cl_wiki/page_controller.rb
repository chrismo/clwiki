require 'cl_wiki/page'

module ClWiki
  class PageController < ApplicationController
    before_action :redirect_legacy_cgi_urls
    before_action :initialize_formatter
    before_action :assign_page_name
    before_action :redirect_to_front_page_if_bad_name, :only => :show

    def show
      @page = instantiate_page
      @page.read_content
      @page
    end

    def edit
      @page = instantiate_page
      @page.read_raw_content
      @page
    end

    def update
      @page = instantiate_page
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
          @formatter.full_name = full_name
          @results << "#{@formatter.convert_to_link(full_name)}"
        end
      end
    end

    def search(text)
      case $wiki_conf.useIndex
        when ClWiki::Configuration::USE_INDEX_NO
          finder = FindInFile.new($wiki_path)
          finder.find(text)
          finder.files.collect do |filename|
            filename.sub(ClWiki::FILE_EXT, '')
          end
        else
          ClWiki::IndexClient.new.search(text)
      end
    end

    def recent
      # TODO: switch to index
      finder = FindInFile.new($wiki_path)
      finder.find($wiki_conf.publishTag || '.')
      @pages = finder.files.collect do |filename|
        p = ClWiki::Page.new(filename.sub(ClWiki::FILE_EXT, ''))
        p.read_page_attributes
        p
      end
      @pages = @pages.sort { |a, b| b.mtime <=> a.mtime }[0..9]
      without_header_and_footer = false
      @pages.each { |p| p.read_content(without_header_and_footer) }

      respond_to do |format|
        format.html
        format.rss { render :layout => false }
      end
    end

    def front_page_name
      'FrontPage'
    end

    def redirect_legacy_cgi_urls
      if request.fullpath.start_with?(legacy_path)
        page_name = (params[:page] || front_page_name).split('/')[-1]
        case
          when request.query_parameters.include?('edit')
            redirect_to page_edit_url(:page_name => page_name), status: '301'
          else
            redirect_to page_show_url(:page_name => page_name), status: '301'
        end
      end
    end

    def assign_page_name
      @page_name = params[:page_name]
      @page_name = @page_name.ensure_slash_prefix if @page_name
    end

    def redirect_to_front_page_if_bad_name
      if ((@page_name.blank?) || (!@formatter.is_wiki_name?(@page_name))) ||
          (!$wiki_conf.editable && !ClWiki::Page.page_exists?(@page_name.ensure_slash_prefix))
        redirect_to page_show_url(:page_name => front_page_name)
        return
      end
    end

    def initialize_formatter
      @formatter = ClWiki::PageFormatter.new
    end

    private

    def instantiate_page
      ClWiki::Page.new(@page_name, owner: current_owner)
    end
  end
end
