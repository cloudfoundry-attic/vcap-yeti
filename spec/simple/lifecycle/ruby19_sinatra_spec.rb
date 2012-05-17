require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Ruby19Sinatra do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
    @app = create_push_app("simple_app2")
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

