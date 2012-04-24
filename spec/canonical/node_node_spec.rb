require "harness"
require "spec_helper"

describe BVT::Spec::Canonical::NodeNode do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:each) do
    @session = BVT::Harness::CFSession.new
    @app = create_app("app_node_service")
    @app.push
    @app.healthy?.should be_true, "Application #{@app.name} is not running"
  end

  after(:each) do
    @session.cleanup!
  end

  def verify_service(service_manifest, app)
    key = "abc"
    data = "#{service_manifest['vendor']}#{key}"
    url = SERVICE_URL_MAPPING[service_manifest['vendor']]
    app.get_response(:post, "/service/#{url}/#{key}", data)
    app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data

    data = "#{data}2"
    app.get_response(:put, "/service/#{url}/#{key}", data)
    app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
  end


  def bind_service_and_verify(service_manifest)
    bind_service(service_manifest, @app)
    verify_service(service_manifest, @app)
  end

  it "node test deploy app" do
    @app.get_response(:get).body_str.should == "hello from node"
    @app.get_response(:get, "/crash").body_str.should =~ /502 Bad Gateway/
  end

  it "node test mysql service" do
    bind_service_and_verify(MYSQL_MANIFEST)
  end

  it "node test redis service" do
    bind_service_and_verify(REDIS_MANIFEST)
  end

  it "node test mongodb service" do
    bind_service_and_verify(MONGODB_MANIFEST)
  end

  it "node test rabbitmq service" do
    bind_service_and_verify(RABBITMQ_MANIFEST)
  end

  it "node test postgresql service" do
    bind_service_and_verify(POSTGRESQL_MANIFEST)
  end
end
