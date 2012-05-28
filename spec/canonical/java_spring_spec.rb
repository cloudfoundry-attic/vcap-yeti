require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Canonical::JavaSpring do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
    @app = create_push_app("app_spring_service")
  end

  after(:all) do
    @session.cleanup!
  end

  it "spring test deploy app", :spring => true do
    contents = @app.get_response(:get)
    contents.should_not == nil
    contents.body_str.should_not == nil
    contents.body_str.should == "hello from spring"
    contents.close

    contents = @app.get_response(:get, '/crash')
    contents.should_not == nil
    contents.response_code.should >= 500
    contents.response_code.should < 600
    contents.close
  end

  it "spring test mysql service", :spring => true, :mysql => true do
    bind_service_and_verify(@app, MYSQL_MANIFEST)
  end

  it "spring test redis service", :spring => true, :redis => true do
    bind_service_and_verify(@app, REDIS_MANIFEST)
  end

  it "spring test mongodb service", :spring => true, :mongodb => true do
    bind_service_and_verify(@app, MONGODB_MANIFEST)
  end

  it "spring test rabbitmq service", :spring => true, :rabbitmq => true do
    bind_service_and_verify(@app, RABBITMQ_MANIFEST)
  end

  it "spring test postgresql service", :spring => true, :postgresql => true do
    bind_service_and_verify(@app, POSTGRESQL_MANIFEST)
  end

end

