require 'spec_helper'

describe "Legacy CGI url support" do
  before do
    @routes = ClWiki::Engine.routes

    # TODO: or maybe the bit about :only_path needing to be set somewheres?
    def @controller.default_url_options
      { :host => 'foo.com' }
    end
  end

  it "should redirect legacy show url" do
    get legacy_path, :page => '/ChrisMorris'

    assert_redirected_to page_show_url(:page_name => 'ChrisMorris', :host => 'foo.com')
  end

  it "should redirect legacy edit url" do
    get legacy_path, :page => '/ChrisMorris', :edit => 'true'

    assert_redirected_to page_edit_url(:page_name => 'ChrisMorris', :host => 'foo.com')
  end
end
