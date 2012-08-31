require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Simple::Node06Standalone do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Simple app with node06 runtime and no URL", :p1 => true do
    app = create_push_app("standalone_node06_app")
    app.logs =~ /it's running version v0.6.8/
  end
end
