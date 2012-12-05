require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Simple::PhpStandalone do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "standalone with php runtime", :p1 => true do
    app = create_push_app("standalone_php_app")

    contents = app.get_response(:get)
    contents.should_not == nil

    response = app.logs
    response.should =~ /Hello from VCAP/
  end
end
