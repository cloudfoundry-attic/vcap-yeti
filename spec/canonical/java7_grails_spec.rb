require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Canonical::Java7Grails do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end


  it "start Spring Grails application using Java 7", :mysql => true do
    app = create_push_app("grails_app_7")
    service = bind_service(MYSQL_MANIFEST, app)

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.body_str.should_not == nil
    contents.response_code.should == 200
    contents.body_str.should =~ /JVM version: 1\.7/
    contents.close

  end

end
