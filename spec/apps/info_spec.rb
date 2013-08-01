require "harness"
require "spec_helper"
include BVT::Spec

describe "Simple::Info" do
  VAR_INSTANCE_COUNT = 4
  VAR_MEMORY         = 64

  context "after an app has been pushed" do
    before(:all) do
      @session = BVT::Harness::CFSession.new
      @simple_app = create_push_app("simple_app2")
    end

    after(:all) do
      @session.cleanup!
    end

    it "query application status" do
      @simple_app.stats.should_not be_nil
    end

    it "can get application files" do
      @simple_app.files("/").should_not be_nil
      @simple_app.files("/app").should_not be_nil
      @simple_app.files("/app/assets/style.css").should_not be_nil
    end

    it "get resource usage information for an application" do
      hash_all = @simple_app.stats["0"]
      hash_all[:state].should == "RUNNING"
      hash_stats = hash_all[:stats]
      arr_name = hash_stats[:name].split("-")
      arr_name[1].should == "simple_app2"
    end

    it "can list multiple applications" do
      java_app = create_push_app("java_tiny_app")

      apps = @session.apps
      apps.map(&:name).should =~ [java_app.name, @simple_app.name]
      apps.all?(&:healthy?).should == true
    end
  end

  context "with individual apps per spec" do
    before(:each) do
      @session = BVT::Harness::CFSession.new
    end

    after(:each) do
      @session.cleanup!
    end

    #should get status on all instances of my application(multiple instances)
    it "get instances information" do
      app = create_push_app("simple_app2")
      app.scale(VAR_INSTANCE_COUNT, VAR_MEMORY)
      app.instances.length.should == VAR_INSTANCE_COUNT
    end


    it "get crash information for an application" do
      app = create_push_app("simple_app2")

      file = app.file('/run.pid')
      file.should_not == nil
      pid = file.chomp

      contents = app.get_response(:get, "/crash/#{pid}")

      crashes = get_crashes(app.name)

      crash = crashes.first
      crash.timestamp.should_not == nil

      app.files("/").should_not == nil
      app.files("/app").should_not == nil
    end

    def get_crashes(name)
      app = @session.find_app(name)
      secs = BVT::Harness::VCAP_BVT_APP_ASSETS["timeout_secs"]
      begin
        crashes = app.events
        secs -= 1
      end while crashes.empty? && secs > 0 && sleep(1)

      if crashes.empty?
        raise "Failed to find crashes for an app."
      end

      crashes
    end
  end
end
