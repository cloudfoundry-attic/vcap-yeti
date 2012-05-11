require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Canonical::JavaStandalone do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "standalone with java runtime", :standalone => true do
    pending "standalone is not supported by VMC libary currently"
    app = create_app("standalone_java_app")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"

    contents = app.get_response(:get)
    contents.should_not == nil

    response = @session.get_app_files(app, '0', 'logs/stdout.log', @token)
    response.should == 'Hello from the cloud.  Java opts:  -Xms256m -Xmx256m'+
    ' -Djava.io.tmpdir=appdir/temp'
  end

end
