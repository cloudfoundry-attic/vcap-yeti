require "harness"
require "spec_helper"

describe BVT::Spec::Simple::JavaStandalone do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "standalone with java runtime", :standalone => true do
    app = create_push_app("standalone_java_app")

    contents = app.get_response(:get)
    contents.should_not == nil

    response = app.logs
    response.should == 'Hello from the cloud.  Java opts:  -Xms64m -Xmx64m'+
    ' -Djava.io.tmpdir=appdir/temp'
  end
end
