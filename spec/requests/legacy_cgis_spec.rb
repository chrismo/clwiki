require 'spec_helper'

describe "Legacy CGI url support" do
  it "should redirect legacy show url" do
    get legacy_path, :page => '/ChrisMorris'

    assert_redirected_to page_show_url(:page_name => 'ChrisMorris')
  end

  it "should redirect legacy edit url" do
    get legacy_path, :page => '/ChrisMorris', :edit => 'true'

    assert_redirected_to page_edit_url(:page_name => 'ChrisMorris')
  end
end
