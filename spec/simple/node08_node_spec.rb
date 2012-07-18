require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Node08Node do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "access my application root and see it's running version v0.8.2" do
    app = create_push_app("app_node_version08")
    app.stats.should_not == nil
    app.get_response(:get).body_str.should == "running version v0.8.2"
  end
end
