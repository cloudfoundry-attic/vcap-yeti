require "harness"
require "spec_helper"

describe BVT::Spec::Simple::JavaWeb do

  before(:each) do
    @client = BVT::Harness::CFSession.new
  end

  after(:each) do
    @client.cleanup!
  end

  it "get applicatioin list", :sinatra => true, :ruby19 => true, :java_web => true do
    app1 = @client.app("simple_app2")
    app1.push

    app2 = @client.app("tiny_java_app")
    app2.push

    app_list = @client.apps
    app_list.each { |app|
      app.healthy?.should be_true, "Application #{app.name} is not running"
    }
  end

  it "start java app with startup delay", :java_web => true do
    app = @client.app("java_app_with_startup_delay")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.body_str.should_not == nil
    contents.body_str.should =~ /I am up and running/
    contents.close
  end
end

