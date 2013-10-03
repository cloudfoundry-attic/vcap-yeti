require "harness"
require "spec_helper"
require "nokogiri"
include BVT::Spec

describe "Simple::JavaJavaWeb", :runtime => true do
  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "start java app with startup delay" do
    app = create_push_app("app_with_startup_delay")

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.to_str.should =~ /I am up and running/
  end

  it "tomcat validation" do
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

