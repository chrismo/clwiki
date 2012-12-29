require 'spec_helper'

describe "Legacy CGI url support" do
  it "works! (now write some real specs)" do
    # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
    get legacy_path, :page => '/ChrisMorris'

    response.status.should be(302)
  end
end
