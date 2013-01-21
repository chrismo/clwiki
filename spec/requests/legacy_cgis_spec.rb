require 'spec_helper'

describe "Legacy CGI url support" do
  it "should redirect legacy show url with leading slash" do
    get legacy_path, use_route: :cl_wiki, :page => '/ChrisMorris'

    assert_redirected_to page_show_path(:page_name => 'ChrisMorris')
  end

  it "should redirect legacy show url without leading slash" do
    get legacy_path, use_route: :cl_wiki, :page => 'ChrisMorris'

    assert_redirected_to page_show_path(:page_name => 'ChrisMorris')
  end

  it 'should support clwikicgi.cgi'

  it 'should redirect legacy url to deep page' do
    get legacy_path, use_route: :cl_wiki, :page => '/SomeParent/DotTest'

    assert_redirected_to page_show_path(:page_name => 'DotTest')
  end

  it "should redirect legacy edit url" do
    get legacy_path, use_route: :cl_wiki, :page => '/ChrisMorris', :edit => 'true'

    assert_redirected_to page_edit_path(:page_name => 'ChrisMorris')
  end
end
