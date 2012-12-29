require 'clwiki/page'

class PageController < ApplicationController
  before_filter :redirect_legacy_cgi_urls
  before_filter :initialize_formatter
  before_filter :front_page_if_bad_name

  def show
    #if !$wiki_conf.editable and !ClWiki::Page.page_exists?(@page_name)
    #  @wiki_page = front_page_name
    #end
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
    redirect_to params[:save_and_edit] ? page_edit_url(:page_name => @page.full_name[1..-1]) : page_show_url(:page_name => @page.full_name[1..-1])
  end

  def front_page_name
    '/FrontPage'
  end

  def redirect_legacy_cgi_urls
    # $stderr.puts "request.path_info #{request.path_info} legacy_path #{legacy_path}"
    if request.path_info == legacy_path
      redirect_to page_show_url(:page_name => params[:page][1..-1])
    end
  end

  def front_page_if_bad_name
    page_name = params[:page_name]
    @page_name = if (page_name.blank?) || (!@formatter.is_wiki_name?(page_name))
                   wiki_name = front_page_name
                 else
                   page_name
                 end
    @page_name = '/' + @page_name if @page_name[0..0] != '/'
  end

  def initialize_formatter
    @formatter = ClWiki::PageFormatter.new
  end
end
