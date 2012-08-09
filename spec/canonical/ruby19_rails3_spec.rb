require "harness"
require "spec_helper"

describe BVT::Spec::Canonical::Ruby19Rails3 do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  before(:each) do
    @app = create_push_app("app_rails_service")
  end

  after(:each) do
    @session.cleanup!
  end

  it "rails3 test deploy app" do
    @app.get_response(:get).body_str.should == "hello from rails"
    @app.get_response(:get, "/crash").body_str.should =~ /502 Bad Gateway/
  end

  it "rails test setting RAILS_ENV" do
    @app.stop
    add_env(@app,'RAILS_ENV','development')
    @app.start

    @app.get_response(:get).body_str.should == "hello from rails"
    logs = @app.logs
    logs.should include "starting in development"
  end

  it "rails3 test mysql service", :mysql => true, :p1 => true do
    bind_service_and_verify(@app, MYSQL_MANIFEST)
  end

  it "rails3 test redis service", :redis => true do
    bind_service_and_verify(@app, REDIS_MANIFEST)
  end

  it "rails3 test mongodb service", :mongodb => true do
    bind_service_and_verify(@app, MONGODB_MANIFEST)
  end

  it "rails3 test rabbitmq service", :rabbitmq => true do
    bind_service_and_verify(@app, RABBITMQ_MANIFEST)
  end

  it "rails3 test postgresql service", :postgresql => true do
    bind_service_and_verify(@app, POSTGRESQL_MANIFEST)
  end
end
