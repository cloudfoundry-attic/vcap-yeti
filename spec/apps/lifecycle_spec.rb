require "harness"
require "spec_helper"
require "securerandom"
include BVT::Spec

describe "App lifecycle" do
  before(:all) { @session = BVT::Harness::CFSession.new }

  describe "app serving web requests" do
    after { @session.cleanup! }

    it "create/start/edit/stop/delete application" do
      # create app
      app = create_push_app("simple_app2")
      app.should_not == nil

      # start app
      app.start
      hash_all = app.stats["0"]
      hash_all[:state].should == "RUNNING"

      # redeploy app
      app.push(nil, "modified_simple_app2")
      app.restart
      app_up?(app)

      # edit
      app.total_instances = 0
      app.update!(:restart => false)
      app.env = {"some_env" => "true"}
      app.update!(:restart => false)
      app_down?(app)
      app.scale(1)
      app_up?(app)

      # stop app
      app.stop
      app_down?(app)

      # delete app
      len = @session.apps.length
      app.delete
      @session.apps.length.should == len - 1
      app_down?(app)
    end

    def app_up?(app)
      wait { app.get("/").should =~ /Hello from modified/ }
    end

    def app_down?(app)
      wait { app.get_response(:get, "/").code.should eq 404 }
    end
  end

  describe "basic app" do
    with_app "basic"

    it "waits for minimum of 30 seconds of inactivity" do
      res = app.get_response(:get, "/sleep?duration=30", "", nil, 100)
      res.to_str.should == "slept for 30 secs"
    end

    it "is able to scale number of instances" do
      original_num_of_instances = app.instances.length
      new_num_of_instances = original_num_of_instances + 2
      original_memory = 512

      app.scale(new_num_of_instances, original_memory)
      wait do |i = app.instances|
        i.map(&:state).uniq.should == ["RUNNING"]
        i.length.should == new_num_of_instances
      end

      app.scale(original_num_of_instances, original_memory)
      wait do |i = app.instances|
        i.map(&:state).uniq.should == ["RUNNING"]
        i.length.should == original_num_of_instances
      end
    end
  end

  # Should be combined with 'basic app' tests above
  # after DEA is fixed to not register instances
  # that are about to be stopped.
  describe "basic app (url mapping)" do
    with_app "basic"

    it "is able to map/unmap a route" do
      new_subdomain = "#{SecureRandom.hex}"

      app.map(app.get_url(new_subdomain))
      wait do
        app.get("/health").should == "ok"
        app.get("/health", new_subdomain).should == "ok"
      end

      app.unmap(app.get_url(new_subdomain))
      wait do
        app.get("/health").should == "ok"
        app.get("/health", new_subdomain).should =~ /404 Not Found/
      end
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

  describe "app that dies of memory overdose" do
    with_app "memory_hog"

    it "dies when we hit the evil endpoint" do
      app.get("/evil").should =~ /502 Bad Gateway/
    end

    def crash_app
      app.get("/evil")

      5.times do
        return if app.events.size > 0
        sleep(1)
      end

      raise "Could not find crash events for '#{app.name}'"
    end

    it "registers a crash event with description 'out of memory'" do
      crash_app
      app.events.first.exit_description.should =~ /out of memory/i
    end

    it "has an exit status that means something" do
      crash_app
      [-1, nil].should_not include(app.events.first.exit_status)
    end
  end
end
