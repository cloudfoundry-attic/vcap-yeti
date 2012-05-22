require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Ruby18Standalone do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Bundled app with ruby 1.8 runtime" do
    app = create_push_app("standalone_ruby18_app")
    app.get_response(:get).body_str.should == "running version 1.8"
  end

  it "Simple app with ruby 1.8 runtime and no URL" do
    app = create_push_app("standalone_simple_ruby18_app")
    app.logs =~ /running version 1.8/
  end

  it "With quotes in command" do
    app = create_push_app("standalone_simple_ruby18_quotes_app")
    app.logs =~ /running version 1.8/
  end
end
