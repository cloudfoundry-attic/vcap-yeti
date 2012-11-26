require "harness"
require "spec_helper"
require "vmc"
include BVT::Spec

describe BVT::Spec::Simple::Info::RubySinatra do

  VAR_INSTANCE_COUNT = 4
  VAR_MEMORY         = 64

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
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
    hash_all = app.stats[:"0"]
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
    @client = VMC::Client.new(@session.TARGET)
    @client.login(@session.email, @session.passwd)

    app = create_push_app("simple_app2")

    files = @client.app_files(app.name, '/run.pid', '0')
    files.should_not == nil
    pid = files.chomp

    contents = app.get_response(:get, "/crash/#{pid}")
    contents.close

    crashes = get_crashes(app.name)

    crash = crashes.first
    crash[:since].should_not be_nil

    verify_files(app.name, crash[:instance], "/")
    verify_files(app.name, crash[:instance], "/app")
  end

  it "get crash information for a broken application" do
    @client = VMC::Client.new(@session.TARGET)
    @client.login(@session.email, @session.passwd)

    app = create_app("broken_app")
    app.push(nil, nil, false)

    crashes = get_crashes(app.name)

    crash = crashes.first
    crash.should include(:instance)

    verify_files(app.name, crash[:instance], "/")
    verify_files(app.name, crash[:instance], "/app")
  end

  def get_crashes(application_name)
    stop = Time.now + 5
    crash_info = nil

    while Time.now < stop
      crash_info = @client.app_crashes(application_name)
      if crash_info[:crashes].empty?
        sleep 1
      else
        break
      end
    end

    crashes = crash_info[:crashes]
    crashes.should_not be_empty, "No crashes"

    crashes
  end

  def verify_files(application_name, instance_id, path)
    files = @client.app_files(application_name, path, instance_id)
    files.should_not be_nil, "No files under #{path}"
  end
end
