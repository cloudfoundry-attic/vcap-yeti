require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::AutoStaging::Ruby18Rack do

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def bind_service(service_manifest, app)
    service = @session.service(service_manifest['vendor'])
    service.create(service_manifest)
    app.bind(service.name)
  end

  def verify_service_autostaging(service_manifest, app)
    key = "abc"
    data = "#{service_manifest['vendor']}#{key}"
    url = SERVICE_URL_MAPPING[service_manifest['vendor']]
    app.get_response(:post, "/service/#{url}/#{key}", data)
    app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
  end

  it "services autostaging" do
    app = @session.app("app_rack_service_autoconfig")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get, "/crash").body_str.should =~ /502 Bad Gateway/

    # provision service
    manifests = [MYSQL_MANIFEST, 
                 REDIS_MANIFEST, 
                 MONGODB_MANIFEST, 
                 RABBITMQ_MANIFEST, 
                 POSTGRESQL_MANIFEST]
    manifests.each do |service_manifest|
      bind_service(service_manifest, app)
      verify_service_autostaging(service_manifest, app)
    end
  end

  it "rack opt-out of autostaging via config file" do
    app = @session.app("rack_autoconfig_disabled_by_file")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    url = "/service/#{service_manifest['vendor']}/connection"
    app.get_response(:get, url).body_str.should == data
  end

  it "rack opt-out of autostaging via cf-runtime gem" do
    app = @session.app("rack_autoconfig_disabled_by_gem")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    url = "/service/#{service_manifest['vendor']}/connection"
    app.get_response(:get, url).body_str.should == data
  end
end
