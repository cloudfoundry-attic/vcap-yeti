require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::AutoStagingHelper

describe BVT::Spec::AutoStaging::Node04Node do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Node.js version 0.4 autostaging", :mysql=>true, :redis=>true,
    :mongodb=>true, :rabbitmq=>true, :postgresql=>true do
    app = push_app_and_verify("node_autoconfig04", "/", "hello from node")

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

  it "Node.js opt-out of autostaging via config file", :redis=>true do
    app = push_app_and_verify("node_autoconfig_disabled_by_file", "/", "hello from node")
    bind_service(REDIS_MANIFEST, app)
    url = SERVICE_URL_MAPPING[REDIS_MANIFEST[:vendor]]

    response = app.get_response(:get, "/service/#{url}/connection")
    response.response_code.should == 200
    response.body_str.should == "Redisconnectionto127.0.0.1:6379failed"
  end

  it "Node.js opt-out of autostaging via cf-runtime module", :redis=>true do
    app = push_app_and_verify("node_autoconfig_disabled_by_module", "/", "hello from node")
    bind_service(REDIS_MANIFEST, app)
    url = SERVICE_URL_MAPPING[REDIS_MANIFEST[:vendor]]

    response = app.get_response(:get, "/service/#{url}/connection")
    response.response_code.should == 200
    response.body_str.should == "Redisconnectionto127.0.0.1:6379failed"
  end
end
