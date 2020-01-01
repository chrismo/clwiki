require 'spec_helper'

describe "Legacy CGI url support" do
  before do
    user = AuthFixture.create_test_user
    post login_url, params: {username: user.username, password: user.password}
  end

  it "should redirect legacy show url with leading slash" do
    get "/wiki/clwikicgi.rb", params: {:page => '/ChrisMorris'}

    assert_redirected_to page_show_path(:page_name => 'ChrisMorris')
  end

  it "should redirect legacy show url without leading slash" do
    get "/wiki/clwikicgi.rb", params: {:page => 'ChrisMorris'}

    assert_redirected_to page_show_path(:page_name => 'ChrisMorris')
  end

  it 'should support clwikicgi.cgi'

  it 'should redirect legacy url to deep page' do
    get "/wiki/clwikicgi.rb", params: {:page => '/SomeParent/DotTest'}

    assert_redirected_to page_show_path(:page_name => 'DotTest')
  end

  it "should redirect legacy edit url" do
    get "/wiki/clwikicgi.rb", params: {:page => '/ChrisMorris', :edit => 'true'}

    assert_redirected_to page_edit_path(:page_name => 'ChrisMorris')
  end
end
