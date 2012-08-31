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

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.body_str.should_not == nil
    contents.response_code.should == 200
    contents.body_str.should =~ /JVM version: 1\.6/
    contents.close

  end

end
