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

  it "standalone with java runtime" do
    app = create_push_app("standalone_java_app")

    contents = app.get_response(:get)
    contents.should_not == nil

    response = app.logs
    response.should include 'Hello from the cloud.  Java opts:  -Xms64m -Xmx64m'+
    ' -Djava.io.tmpdir=appdir/temp'
  end

  it "Deploy Standalone App with Java 6 runtime" do
    app = create_push_app("standalone_java_app")

    contents = app.get_response(:get)
    contents.should_not == nil

    response = app.logs
    response.should =~ /Java version: 1\.6/
  end
end
