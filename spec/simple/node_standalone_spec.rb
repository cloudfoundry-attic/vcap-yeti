require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Simple::NodeStandalone do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Simple app with node runtime and no URL", :p1 => true do
    app = create_push_app("standalone_node_app")
    app.logs =~ /it's running version v0.4.12/
  end
end
