require "harness"
require "spec_helper"

describe BVT::Spec::Canonical::Ruby18Rack do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  before(:each) do
    @app = create_push_app("app_rack_service")
  end

  after(:each) do
    @session.cleanup!
  end

  it "rack test deploy app", :p1 => true do
    @app.get_response(:get).body_str.should == "hello from sinatra"
    @app.get_response(:get, "/crash").body_str.should =~ /502 Bad Gateway/
  end

  it "rack test setting RACK_ENV" do
    add_env(@app,'RACK_ENV','development')
    @app.stop
    @app.start

    @app.get_response(:get,"/rack/env").response_code.should == 200
    @app.get_response(:get,"/rack/env").body_str.should == 'development'
  end

  it "rack test mysql service", :mysql => true, :p1 => true do
    bind_service_and_verify(@app, MYSQL_MANIFEST)
  end

  it "rack test redis service", :redis => true do
    bind_service_and_verify(@app, REDIS_MANIFEST)
  end

  it "rack test mongodb service", :mongodb => true do
    bind_service_and_verify(@app, MONGODB_MANIFEST)
  end

  it "rack test rabbitmq service", :rabbitmq => true do
    bind_service_and_verify(@app, RABBITMQ_MANIFEST)
  end

  it "rack test postgresql service", :postgresql => true do
    bind_service_and_verify(@app, POSTGRESQL_MANIFEST)
  end
end
