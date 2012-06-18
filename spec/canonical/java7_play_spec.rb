require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Canonical::Java7Play do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def bind_service_to_unstarted_app(service, app)
    manifest = {}
    manifest['services'] = [service]
    app.update!(manifest)
  end


  it "Deploy Play Application using Java 7 with mysql auto-reconfiguration" do
    pending "not running because java7 runtime not installed"
    app = create_push_app("play_todolist_app_7")

    bind_service( MYSQL_MANIFEST, app )

    contents = app.get_response(:get, '/java')
    contents.should_not == nil
    contents.body_str.should_not  == nil
    contents.body_str.should =~ /1\.7/
    contents.response_code.should == 200
    contents.close

    app.stats.should_not == nil

    contents = app.get_response(:get, '/tasks')
    contents.should_not == nil
    contents.body_str.should_not  == nil
    contents.response_code.should == 200
    contents.close

    log = app.logs
    log.should_not == nil
    log.should include "Auto-reconfiguring default"
    log.should include "database [default] connected at jdbc:mysql"
  end


end
