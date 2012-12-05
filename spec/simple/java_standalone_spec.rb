require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Simple::JavaStandalone do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "standalone with java runtime", :p1 => true do
    app = create_push_app("standalone_java_app")

    contents = app.get_response(:get)
    contents.should_not == nil

    runtime = app.manifest['runtime']
    version = VCAP_BVT_SYSTEM_RUNTIMES[runtime][:version]
    response = app.logs
    response.should =~ /Java version: #{version}/
    response.should include 'Hello from the cloud.  Java opts:  -Xms64m -Xmx64m'+
    ' -Djava.io.tmpdir=appdir/tmp'
  end

end
