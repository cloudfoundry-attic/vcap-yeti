require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Ruby19Sinatra do
  include BVT::Spec

  VAR_APPNAME = "simple_app2"

  before(:each) do
    @session = BVT::Harness::CFSession.new
    @app = create_app(VAR_APPNAME)
    @app.push
    @app.healthy?.should be_true, "Application #{@app.name} is not running"
  end

  after(:each) do
    @session.cleanup!
  end

  it "create application" do
    @app.should_not == nil
  end

  it "start application" do
    @app.start
    hash_all = @app.stats["0"]
    hash_all["state"].should == "RUNNING"
  end

  it "stop application" do
    @app.stop
    @session.apps[0].stats == {}
  end

  it "delete application" do
    len = @session.apps.length
    @app.delete
    @session.apps.length.should == len - 1
  end

end