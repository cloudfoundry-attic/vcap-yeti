require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::AutoStagingHelper

describe BVT::Spec::AutoStaging::RubyRack do

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "rack ruby 1.9 autostaging", :redis => true do
    service_manifest = REDIS_MANIFEST
    app = create_push_app("rack_autoconfig_ruby19", nil, nil, [service_manifest])
    app.get_response(:get).to_str.should == "hello from sinatra"

    # provision service
    key = "abc"
    data = "#{service_manifest[:vendor]}#{key}"
    url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
    app.get_response(:post, "/service/#{url}/#{key}", data)
    app.get_response(:get, "/service/#{url}/#{key}").to_str.should == data
  end

  it "services autostaging", :mysql => true, :redis => true, :mongodb => true,
    :rabbitmq => true, :postgresql => true, :p1 => true do
    manifests = [
      MYSQL_MANIFEST,
      REDIS_MANIFEST,
      MONGODB_MANIFEST,
      RABBITMQ_MANIFEST,
      POSTGRESQL_MANIFEST
    ]
    app = create_push_app("app_rack_service_autoconfig", nil, nil, manifests)
    manifests.each do |service_manifest|
      verify_service_autostaging(service_manifest, app)
    end
  end

  it "rack opt-out of autostaging via config file", :redis => true do
    app = create_push_app("rack_autoconfig_disabled_by_file")
    app.get_response(:get).to_str.should == "hello from sinatra"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    url = "/service/#{service_manifest[:vendor]}/connection"
    app.get_response(:get, url).to_str.should == data
  end

  it "rack opt-out of autostaging via cf-runtime gem", :redis => true do
    app = create_push_app("rack_autoconfig_disabled_by_gem")
    app.get_response(:get).to_str.should == "hello from sinatra"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    url = "/service/#{service_manifest[:vendor]}/connection"
    app.get_response(:get, url).to_str.should == data
  end
end
