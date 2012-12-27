require 'clwiki/page'

class WikiController < ApplicationController
  before_filter :initialize_formatter
  before_filter :front_page_if_bad_name

  def index
    #if !$wiki_conf.editable and !ClWiki::Page.page_exists?(@page_name)
    #  @wiki_page = front_page_name
    #end
    @page = ClWiki::Page.new(@page_name)
    @page.read_content
    @page
  end
  
  def front_page_name
    '/FrontPage'
  end

  def front_page_if_bad_name
    page_name = params[:page_name]
    @page_name = if (page_name.blank?) || (!@formatter.is_wiki_name?(page_name))
      wiki_name = front_page_name
    else
      page_name
    end
  end

  def initialize_formatter
    @formatter = ClWiki::PageFormatter.new
  end
end
