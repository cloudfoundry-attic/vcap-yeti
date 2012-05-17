require "harness"
require "spec_helper"

describe BVT::Spec::Canonical::Ruby19Rails3 do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
    @app = create_push_app("app_rails_service")
  end

  after(:all) do
    @session.cleanup!
  end

  it "sinatra test deploy app" do
    @app.get_response(:get).body_str.should == "hello from rails"
    @app.get_response(:get, "/crash").body_str.should =~ /502 Bad Gateway/
  end

  it "sinatra test mysql service" do
    bind_service_and_verify(@app, MYSQL_MANIFEST)
  end

  it "sinatra test redis service" do
    bind_service_and_verify(@app, REDIS_MANIFEST)
  end

  it "sinatra test mongodb service" do
    bind_service_and_verify(@app, MONGODB_MANIFEST)
  end

  it "sinatra test rabbitmq service" do
    bind_service_and_verify(@app, RABBITMQ_MANIFEST)
  end

  it "sinatra test postgresql service" do
    bind_service_and_verify(@app, POSTGRESQL_MANIFEST)
  end
end
