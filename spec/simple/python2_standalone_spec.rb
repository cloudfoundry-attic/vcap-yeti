require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Python2Standalone do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "standalone with python runtime", :standalone => true do
    app = create_push_app("standalone_python_app")

    contents = app.get_response(:get)
    contents.should_not == nil

    response = app.logs
    response.should == 'Hello, World!'
  end
end
