require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Java7Standalone do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Deploy Standalone App with Java 7 runtime" do
    app = create_push_app("standalone_java_app_7")

    contents = app.get_response(:get)
    contents.should_not == nil

    status = app.stats
    status.should_not == nil

    log = app.logs
    log.should include "Java version: 1.7"
    log.should include "Hello from the cloud.  Java opts:  -Xms256m -Xmx256m -Djava.io.tmpdir=appdir/temp"
  end

end
