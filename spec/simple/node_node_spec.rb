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

  it "access my application root and see it's running version",
    :p1 => true do
    app = create_push_app("app_node_version04")
    runtime = app.manifest['runtime']
    version = VCAP_BVT_SYSTEM_RUNTIMES[runtime][:version]
    app.stats.should_not == nil
    app.get_response(:get).should_not == nil
    app.get_response(:get).body_str.should_not == nil
    app.get_response(:get).body_str.should == "running version v#{version}"
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

  it "access my application root and see hello from express", :p1 => true do
    app = create_push_app("app_node_dependencies06")
    app.stats.should_not == nil
    app.get_response(:get).should_not == nil
    app.get_response(:get).body_str.should_not == nil
    app.get_response(:get).body_str.should == "hello from express"
  end

  it "access my application root and see hello from node-gyp", :p1 => true do
    app = create_push_app("app_node_dependencies08")
    app.stats.should_not == nil
    app.get_response(:get).body_str.should == "hello from node-gyp"
  end
end
