require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::CanonicalHelper

describe "Canonical::JavaGrails" do

  before { @session = BVT::Harness::CFSession.new }

  after do
    show_crashlogs
    @session.cleanup!
  end

  it "start Spring Grails application using Java 6", :mysql => true, :p1 => true do
    app = create_push_app("grails_app", nil, nil, [MYSQL_MANIFEST])
    contents = app.get_response(:get)
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200
    contents.to_str.should =~ /JVM version: 1.6/
  end
end
