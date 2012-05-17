require "harness"
require "spec_helper"
require "nokogiri"

describe BVT::Spec::Simple::JavaWeb do

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "get applicatioin list", :sinatra => true, :ruby19 => true, :java_web => true do
    app1 = create_push_app("simple_app2")

    app2 = create_push_app("tiny_java_app")

    app_list = @session.apps
    app_list.each { |app|
      app.healthy?.should be_true, "Application #{app.name} is not running"
    }
  end

  it "start java app with startup delay", :java_web => true do
    app = create_push_app("java_app_with_startup_delay")

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.body_str.should_not == nil
    contents.body_str.should =~ /I am up and running/
    contents.close
  end

  it "tomcat validation", :java_web => true do
    app = create_push_app("tomcat-version-check-app")

    response = app.get_response(:get)
    response.should_not == nil
    response.response_code.should == 200
    response.body_str.should_not == nil

    doc = Nokogiri::XML(response.body_str)
    version = doc.xpath("//version").first.content
    version.should_not == nil
    version.should =~ /Apache Tomcat/

    packaged_version = app.manifest['tomcat_version']
    packaged_version.should_not == nil
    # The Tomcat version reported by the servlet is of the form
    # 'Apache Tomcat/6.0.xx' for Tomcat 6 based releases.
    version.split('/')[1].should == packaged_version
  end
end

