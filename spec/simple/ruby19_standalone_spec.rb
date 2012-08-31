require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Simple::Ruby19Standalone do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Bundled app with ruby 1.9 runtime" do
    app = create_push_app("standalone_ruby19_app")
    app.get_response(:get).body_str.should == "running version 1.9"
  end

  it "Simple app with ruby 1.9 runtime and no URL" do
    app = create_push_app("standalone_simple_ruby19_app")
    app.logs =~ /running version 1.9/
  end
end
