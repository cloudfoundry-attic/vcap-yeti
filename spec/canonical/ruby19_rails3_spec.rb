require "harness"
require "spec_helper"

describe BVT::Spec::Canonical::Ruby19Rails3 do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:each) do
    @session = BVT::Harness::CFSession.new
    @app = create_app("app_rails_service")
    @app.push
    @app.healthy?.should be_true, "Application #{@app.name} is not running"
  end

  after(:each) do
    @session.cleanup!
  end

  def bind_service_and_verify(service_manifest)
    bind_service(service_manifest, @app)
    %W(abc 123 def).each { |key| verify_service(service_manifest, @app, key)}
  end

  it "rails3 test deploy app" do
    @app.get_response(:get).body_str.should == "hello from rails"
    @app.get_response(:get, "/crash").body_str.should =~ /502 Bad Gateway/
  end

  it "rails3 test mysql service" do
    bind_service_and_verify(MYSQL_MANIFEST)
  end

  it "rails3 test redis service" do
    bind_service_and_verify(REDIS_MANIFEST)
  end

  it "rails3 test mongodb service" do
    bind_service_and_verify(MONGODB_MANIFEST)
  end

  it "rails3 test rabbitmq service" do
    bind_service_and_verify(RABBITMQ_MANIFEST)
  end

  it "rails3 test postgresql service" do
    bind_service_and_verify(POSTGRESQL_MANIFEST)
  end
end
