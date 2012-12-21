require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Simple::PhpPhp do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Deploy Simple PHP Application", :p1 => true do
    app = create_push_app("simple_php_app")

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.to_str.should =~ /Hello from VCAP/
  end
end
