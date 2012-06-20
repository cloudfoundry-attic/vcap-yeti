require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Node06Node do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "access my application root and see it's running version v0.6.8" do
    app = create_push_app("app_node_version06")
    app.stats.should_not == nil
    app.get_response(:get).should_not == nil
    app.get_response(:get).body_str.should_not == nil
    app.get_response(:get).body_str.should == "running version v0.6.8"
  end

  it "access my application root and see hello from express", :p1 => true do
    app = create_push_app("app_node_dependencies06")
    app.stats.should_not == nil
    app.get_response(:get).should_not == nil
    app.get_response(:get).body_str.should_not == nil
    app.get_response(:get).body_str.should == "hello from express"
  end
end
