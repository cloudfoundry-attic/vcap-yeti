require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Python2Wsgi do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Deploy Simple Python Application", :p1 => true do
    app = create_push_app("simple_wsgi_app")

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.body_str.should =~ /Hello from VCAP/
    contents.close
  end

  it "Deploy Python Application With Dependency" do
    app = create_push_app("wsgi_app_with_requirements")

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.body_str.should =~ /Hello from VCAP/
    contents.close
  end
end
