require "harness"
require "spec_helper"

describe BVT::Spec::Simple::NodeNode do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "access my application root and see it's running version v0.4.12" do
    @app = create_app("app_node_version04")
    @app.push
    @app.healthy?.should be_true, "Application #{@app.name} is not running"
    @app.stats.should_not == nil
    @app.get_response(:get).should_not == nil
    @app.get_response(:get).body_str.should_not == nil
    @app.get_response(:get).body_str.should == "running version v0.4.12"
  end

  it "access my application root and see hello from express" do
    @app = create_app("app_node_dependencies04")
    @app.push
    @app.healthy?.should be_true, "Application #{@app.name} is not running"
    @app.stats.should_not == nil
    @app.get_response(:get).should_not == nil
    @app.get_response(:get).body_str.should_not == nil
    @app.get_response(:get).body_str.should == "hello from express"
  end
end
