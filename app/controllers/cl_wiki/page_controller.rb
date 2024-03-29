# frozen_string_literal: true

require 'cl_wiki/page'

module ClWiki
  class PageController < ApplicationController
    before_action :redirect_legacy_cgi_urls
    before_action :initialize_formatter
    before_action :assign_page_name
    before_action :redirect_to_front_page_if_bad_name, only: :show
    before_action :redirect_to_show_if_read_only, only: [:edit, :update]
    skip_before_action :expire_old_session, only: [:edit, :update]

    def show
      @page = instantiate_page
      @page.read_content
      @page
    end

    def edit
      @render_encryption_ui = $wiki_conf.use_authentication

      @page = instantiate_page
      @encrypt_default = determine_encryption_default

      @page.read_raw_content
      @page
    end

    def update
      @page = instantiate_page

      mtime = Time.at(params[:client_mod_time].to_s.to_i)
      encrypt = params[:encrypt].present?
      @page.update_content(params[:page_content], mtime, encrypt)

      redirect_to params[:save_and_edit] ?
                    page_edit_url(page_name: @page.page_name) :
                    page_show_url(page_name: @page.page_name)
    end

    def find
      @formatter = ClWiki::PageFormatter.new
      @search_text = params[:search_text]
      @results = []
      if @search_text
        hits = search(@search_text)

        hits.each do |full_name|
          @formatter.full_name = full_name
          @results << @formatter.convert_to_link(full_name).to_s
        end
      end
    end

    def search(text)
      ClWiki::MemoryIndexer.instance.search(text)
    end

    # recent _published_ pages.
    def recent
      page_names = ClWiki::MemoryIndexer.instance.recent(10, text: $wiki_conf.publishTag)

      without_header_and_footer = false
      @pages = page_names.map do |page_name|
        ClWiki::Page.new(page_name, owner: current_owner).tap do |page|
          page.read_content(without_header_and_footer)
        end
      end

      respond_to do |format|
        format.html
        format.rss { render layout: false }
      end
    end

    def front_page_name
      'FrontPage'
    end

    def redirect_legacy_cgi_urls
      if request.fullpath.start_with?(legacy_path)
        page_name = (params[:page] || front_page_name).split('/')[-1]
        if request.query_parameters.include?('edit')
          redirect_to page_edit_url(page_name: page_name), status: '301'
        else
          redirect_to page_show_url(page_name: page_name), status: '301'
        end
      end
    end

    def assign_page_name
      @page_name = params[:page_name]
    end

    def redirect_to_front_page_if_bad_name
      if (@page_name.blank? || !@formatter.is_wiki_name?(@page_name)) ||
         (!$wiki_conf.editable && !ClWiki::Page.page_exists?(@page_name))
        redirect_to page_show_url(page_name: front_page_name)
        nil
      end
    end

    def redirect_to_show_if_read_only
      unless $wiki_conf.editable
        redirect_to page_show_url(page_name: @page_name)
        nil
      end
    end

    def initialize_formatter
      @formatter = ClWiki::PageFormatter.new
    end

    private

    def instantiate_page
      ClWiki::Page.new(@page_name, owner: current_owner)
    end

    def determine_encryption_default
      if $wiki_conf.use_authentication
        @page.is_new? ? $wiki_conf.encryption_default : @page.content_encrypted?
      else
        false
      end
    end
  end
end
