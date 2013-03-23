require "harness"
require "spec_helper"
include BVT::Spec

describe "Simple::Lifecycle" do
  before(:all) { @session = BVT::Harness::CFSession.new }

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

  #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # reconsider how to tes
  #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  it "is able to run an app that does not bind to ports" do
    app = create_push_app("standalone_simple_ruby_app")
    app.logs =~ /running version/
  end
end
