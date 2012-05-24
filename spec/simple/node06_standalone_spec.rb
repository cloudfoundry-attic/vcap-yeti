require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Node06Standalone do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Simple app with node06 runtime and no URL" do
    app = create_push_app("standalone_node06_app")
    app.logs =~ /it's running version v0.6.8/
  end
end
