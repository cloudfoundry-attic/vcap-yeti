require "harness"
require "spec_helper"
require "nokogiri"
include BVT::Spec

describe "Simple::JavaJavaWeb" do

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    show_crashlogs
    @session.cleanup!
  end

  it "get application list", :slow => true, :p1 => true do
    app1 = create_push_app("simple_app2")
    app2 = create_push_app("tiny_java_app")

    app_list = @session.apps
    app_list.each { |app|
      app.healthy?.should be_true, "Application #{app.name} is not running"
    }
  end

  it "start java app with startup delay", :slow => true do
    app = create_push_app("java_app_with_startup_delay")

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.to_str.should =~ /I am up and running/
  end

  it "tomcat validation", :p1 => true do
    app = create_push_app("tomcat-version-check-app")

    response = app.get_response(:get)
    response.should_not == nil
    response.code.should == 200
    response.to_str.should_not == nil

    doc = Nokogiri::XML(response.to_str)
    version = doc.xpath("//version").first.content
    version.should_not == nil
    version.should =~ /Apache Tomcat/
  end
end

