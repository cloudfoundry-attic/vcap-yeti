require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Info::Ruby19Sinatra do
  include BVT::Spec

  VAR_INSTANCE_COUNT = 4
  VAR_MEMORY         = 64

  before(:all) do
    @session = BVT::Harness::CFSession.new
    @app = create_push_app("simple_app2")
  end

  after(:all) do
    @session.cleanup!
  end

  #should get the state of my application
  it "query application status" do
    @app.stats.should_not == nil
  end

  #should get a list of dir and files associated with my application on APpCloud
  #AND can retrieve any of listed files
  it "get application files" do
    @app.files("/").should_not == nil
    @app.files("/app").should_not == nil
  end

  #should get status on all instances of my application(multiple instances)
  it "get instances information" do
    @app.scale(VAR_INSTANCE_COUNT, VAR_MEMORY)
    @app.instances.length.should == VAR_INSTANCE_COUNT
  end

  #should get app_name & status
  it "get resource usage information for an application" do
    hash_all = @app.stats["0"]
    hash_all["state"].should == "RUNNING"
    hash_stats = hash_all["stats"]
    arr_name = hash_stats["name"].split("-")
    arr_name[1].should == "simple_app2"
  end

end
