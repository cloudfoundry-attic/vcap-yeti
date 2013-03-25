require "harness"
require "spec_helper"
include BVT::Spec

describe "App lifecycle" do
  before(:all) { @session = BVT::Harness::CFSession.new }

  describe "app serving web requests" do
    after(:each) do
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

  describe "slow responding app" do
    with_app "basic"

    it "waits for long responses" do
      res = app.get_response(:get, "/sleep?duration=75", "", nil, 100)
      res.to_str.should == "slept for 75 secs"
    end
  end

  describe "background worker app (no bound uris)" do
    with_app "worker"

    def check_logs(app, match)
      logs = nil
      15.times do
        logs = app.logs
        return if logs.include?(match)
        sleep(2)
      end
      raise "Could not find '#{match}' in '#{logs}'"
    end

    it "continues to run" do
      check_logs(app, "running for 5 secs")
      check_logs(app, "running for 10 secs")
      check_logs(app, "running for 15 secs")
      check_logs(app, "running for 20 secs")
    end
  end
end
