require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Simple::Python2Django do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Deploy Django Application", :p1 => true do
    app = create_push_app("simple_django_app")

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.to_str.should =~ /Hello from VCAP/
  end
end
