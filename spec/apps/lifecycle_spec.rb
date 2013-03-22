require "harness"
require "spec_helper"
include BVT::Spec

describe "Simple::Lifecycle" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    show_crashlogs
    @session.cleanup!
  end

  it "create/start/stop/delete application" do
    # create app
    app = create_push_app("simple_app2")
    app.should_not == nil

    # start app
    app.start
    hash_all = app.stats["0"]
    hash_all[:state].should == "RUNNING"

    # stop app
    app.stop
    app.stats == {}

    # delete app
    len = @session.apps.length
    app.delete
    @session.apps.length.should == len - 1
  end

end

