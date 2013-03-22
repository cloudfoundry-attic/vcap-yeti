require "spec_helper"

describe "app response timeout" do
  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    show_crashlogs
    @session.cleanup!
  end

  it "app should not timeout if it doesn't respond for 75 seconds" do
    app = create_push_app("sleeper")
    app.get_response(:get, "/75", "", nil, 100).to_str.should == "slept for 75 seconds"
  end
end
