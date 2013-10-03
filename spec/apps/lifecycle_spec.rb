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
      app.stop
      app.push(nil, "modified_simple_app2")
      app.start
      app_up?(app)

      # edit
      app.scale(0)
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

    it "continues to run" do
      wait(4) { expect(app.logs).to include("running for 1.0 secs") }
      wait(4) { expect(app.logs).to include("running for 1.5 secs") }
    end
  end

  describe "app that dies of memory overdose", exclude_in_warden_cpi: true do
    with_app "memory_hog"

    it "correctly has events" do
      # ensuring that en event is created for the crash
      expect(app.get("/evil")).to match /502 Bad Gateway/
      wait { expect(app.events.size).to be > 0 }

      # listing the correct out of memory exception
      expect(app.events.first.exit_description).to match /out of memory/i

      # including the correct exit status
      expect([-1, nil]).to_not include(app.events.first.exit_status)
    end
  end
end
