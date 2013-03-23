require "harness"
require "spec_helper"
include BVT::Spec

describe "Simple::Info" do
  VAR_INSTANCE_COUNT = 4
  VAR_MEMORY         = 64

  before(:all) do
    @session = BVT::Harness::CFSession.new
    @client = @session.client
  end

  after(:each) do
    show_crashlogs
    @session.cleanup!
  end

  def get_app_info(apps, appname)
    if apps.empty?
      return
    end
    apps.each { |d|
      if d.name == appname
        return d
      end
    }
  end

  #should get the state of my application
  it "query application status" do
    app = create_push_app("simple_app2")
    app.stats.should_not == nil
  end

  #should get a list of dir and files associated with my application on APpCloud
  #AND can retrieve any of listed files
  it "get application files" do
    app = create_push_app("simple_app2")
    app.files("/").should_not == nil
    app.files("/app").should_not == nil
  end

  #should get status on all instances of my application(multiple instances)
  it "get instances information" do
    app = create_push_app("simple_app2")
    app.scale(VAR_INSTANCE_COUNT, VAR_MEMORY)
    app.instances.length.should == VAR_INSTANCE_COUNT
  end

  #should get app_name & status
  it "get resource usage information for an application" do
    app = create_push_app("simple_app2")
    hash_all = app.stats["0"]
    hash_all[:state].should == "RUNNING"
    hash_stats = hash_all[:stats]
    arr_name = hash_stats[:name].split("-")
    arr_name[1].should == "simple_app2"
  end

  it "list applications" do
    app = create_push_app("simple_app2")
    app2 = create_push_app("tiny_java_app")

    apps = @session.apps
    apps.should_not == nil

    simple_app = get_app_info(apps, app.name)
    tiny_java_app = get_app_info(apps, app2.name)

    simple_app.should_not == nil
    tiny_java_app.should_not == nil
  end

  it "get crash information for an application" do
    app = create_push_app("simple_app2")

    file = app.file('/run.pid')
    file.should_not == nil
    pid = file.chomp

    contents = app.get_response(:get, "/crash/#{pid}")

    crashes = get_crashes(app.name)

    crash = crashes.first
    crash.since.should_not == nil

    crash.files("/").should_not == nil
    crash.files("/app").should_not == nil
  end

  def get_crashes(name)
    app = @client.app_by_name(name)
    secs = VCAP_BVT_APP_ASSETS["timeout_secs"]

    begin
      crashes = app.crashes
      secs -= 1
    end while crashes.empty? && secs > 0 && sleep(1)

    if crashes.empty?
      raise "Failed to find crashes for an app."
    end

    crashes
  end
end
