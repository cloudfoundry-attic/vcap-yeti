require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::CanonicalHelper

describe BVT::Spec::Canonical::JavaGrails do

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "start Spring Grails application using Java 6", :mysql => true,
    :p1 => true do
    app = create_push_app("grails_app")
    service = bind_service(MYSQL_MANIFEST, app)

    runtime = app.manifest['runtime']
    version = VCAP_BVT_SYSTEM_RUNTIMES[runtime][:version]

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200
    contents.to_str.should =~ /JVM version: #{version}/

  end

end
