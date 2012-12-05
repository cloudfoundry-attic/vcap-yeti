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
    app = create_push_app("rack_autoconfig_ruby19")
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    key = "abc"
    data = "#{service_manifest[:vendor]}#{key}"
    url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
    app.get_response(:post, "/service/#{url}/#{key}", data)
    app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
  end

  it "services autostaging", :mysql => true, :redis => true, :mongodb => true,
    :rabbitmq => true, :postgresql => true, :p1 => true do
    app = create_push_app("app_rack_service_autoconfig")
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

  it "rack opt-out of autostaging via config file", :redis => true do
    app = create_push_app("rack_autoconfig_disabled_by_file")
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    url = "/service/#{service_manifest[:vendor]}/connection"
    app.get_response(:get, url).body_str.should == data
  end

  it "rack opt-out of autostaging via cf-runtime gem", :redis => true do
    app = create_push_app("rack_autoconfig_disabled_by_gem")
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    url = "/service/#{service_manifest[:vendor]}/connection"
    app.get_response(:get, url).body_str.should == data
  end
end
