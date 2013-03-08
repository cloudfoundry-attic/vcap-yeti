require "harness"
require "spec_helper"
include BVT::Spec

describe "Simple::Node" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    show_crashlogs
    @session.cleanup!
  end

  it "access my application root and see it's running version",
    :p1 => true do
    app = create_push_app("app_node_version04")
    app.stats.should_not == nil
    app.get_response(:get).should_not == nil
    app.get_response(:get).to_str.should_not == nil
    app.get_response(:get).to_str.should =~ /running version v0.4/
  end

  it "access my application root and see hello from git" do
    app = create_push_app("node_git_modules")
    app.stats.should_not == nil
    app.get_response(:get).should_not == nil
    app.get_response(:get).to_str.should_not == nil
    app.get_response(:get).to_str.should == "hello from git"
  end

  it "access my application root and see hello from express", :p1 => true do
    app = create_push_app("app_node_dependencies06")
    app.stats.should_not == nil
    app.get_response(:get).should_not == nil
    app.get_response(:get).to_str.should_not == nil
    app.get_response(:get).to_str.should == "hello from express"
  end

  it "access my application root and see hello from node-gyp", :p1 => true do
    app = create_push_app("app_node_dependencies08")
    app.stats.should_not == nil
    app.get_response(:get).to_str.should == "hello from node-gyp"
  end

  it "Simple node app and no URL", :p1 => true do
    app = create_push_app("standalone_node_app")
    app.logs =~ /it's running version v0.4/
  end
end
