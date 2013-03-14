require "harness"
require "spec_helper"
include BVT::Spec

describe "Simple::Java" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    show_crashlogs
    @session.cleanup!
  end

  it "simple java app", :p1 => true do
    app = create_push_app("standalone_java_app")

    contents = app.get_response(:get)
    contents.should_not == nil

    response = app.logs
    response.should =~ /Java version: 1.6/
    response.should include '-Xms512m'
    response.should include '-Djava.io.tmpdir=appdir/tmp'
  end

end
