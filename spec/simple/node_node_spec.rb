require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Simple::NodeNode do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "access my application root and see it's running version v0.4.12",
    :p1 => true do
    app = create_push_app("app_node_version04")
    app.stats.should_not == nil
    app.get_response(:get).should_not == nil
    app.get_response(:get).body_str.should_not == nil
    app.get_response(:get).body_str.should == "running version v0.4.12"
  end

  it "access my application root and see hello from express" do
    app = create_push_app("app_node_dependencies04")
    app.stats.should_not == nil
    app.get_response(:get).should_not == nil
    app.get_response(:get).body_str.should_not == nil
    app.get_response(:get).body_str.should == "hello from express"
  end

  it "access my application root and see hello from git" do
    app = create_push_app("node_git_modules")
    app.stats.should_not == nil
    app.get_response(:get).should_not == nil
    app.get_response(:get).body_str.should_not == nil
    app.get_response(:get).body_str.should == "hello from git"
  end
end
