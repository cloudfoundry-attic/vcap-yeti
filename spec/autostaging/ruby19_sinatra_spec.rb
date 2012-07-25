require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::AutoStaging::Ruby19Sinatra do
  include BVT::Spec::AutoStagingHelper

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def push_app_and_verify(app_name, relative_url, response_str)
    app = create_app(app_name)
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get, relative_url).body_str.should =~ /#{response_str}/
    app
  end

  it "services autostaging", :mysql => true, :mongodb => true, :rabbitmq => true,
    :postgresql => true, :redis => true, :p1 => true do
    app = push_app_and_verify("app_sinatra_service_autoconfig",
                              "/crash", "502 Bad Gateway")
    # provision service
    manifests = [MYSQL_MANIFEST, REDIS_MANIFEST, MONGODB_MANIFEST,
                 RABBITMQ_MANIFEST, POSTGRESQL_MANIFEST]
    manifests.each do |service_manifest|
      bind_service(service_manifest, app)
      verify_service_autostaging(service_manifest, app)
    end
  end

  it "Sinatra AMQP autostaging", :rabbitmq => true do
    app = push_app_and_verify("amqp_autoconfig", "/", "hello from sinatra")
    # provision service
    service_manifest = RABBITMQ_MANIFEST
    bind_service(service_manifest, app)
    data = "#{service_manifest[:vendor]}abc"
    app.get_response(:post, "/service/amqpurl/abc", data)
    app.get_response(:get, "/service/amqpurl/abc").body_str.should == data

    app.get_response(:post, "/service/amqpoptions/abc", data)
    app.get_response(:get, "/service/amqpoptions/abc").body_str.should == data
  end

  it "Autostaging with unsupported client versions", :mysql => true,
    :redis => true, :rabbitmq => true, :mongodb => true, :postgresql => true do
    app = push_app_and_verify("autoconfig_unsupported_versions", "/",
                              "hello from sinatra")
    # provision service
    testdata = [{:service => MYSQL_MANIFEST,
                 :data => "Can'tconnecttoMySQLserveron'127.0.0.1'(111)"},
                {:service => REDIS_MANIFEST,
                 :data => "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"},
                {:service => RABBITMQ_MANIFEST,
                 :data => "Couldnotconnecttoserver127.0.0.1:4567"},
                {:service => POSTGRESQL_MANIFEST,
                 :data => "couldnotconnecttoserver:ConnectionrefusedIstheserverrunningonhost" +
                     "\"127.0.0.1\"andacceptingTCP/IPconnectionsonport8675?"},
                {:service => MONGODB_MANIFEST,
                 :data => "Failedtoconnecttoamasternodeat127.0.0.1:4567"}]
    testdata.each do |item|
      bind_service(item[:service], app)
      verify_unsupported_client_version(item[:service], app, item[:data])
    end
  end

  it "Autostaging with unsupported carrot version", :rabbitmq => true do
    app = push_app_and_verify("autoconfig_unsupported_carrot_version", "/",
                              "hello from sinatra")
    # provision service
    service_manifest = RABBITMQ_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-connect(2)-127.0.0.1:1234"
    app.get_response(:get, "/service/carrot/connection").body_str.should == data
  end

  it "Sinatra opt-out of autostaging via config file", :redis => true do
    app = push_app_and_verify("sinatra_autoconfig_disabled_by_file", "/",
                              "hello from sinatra")
    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    app.get_response(:get, "/service/#{service_manifest[:vendor]}/connection").body_str.should == data
  end

  it "Sinatra opt-out of autostaging via cf-runtime gem", :redis => true do
    app = push_app_and_verify("sinatra_autoconfig_disabled_by_gem",  "/",
                              "hello from sinatra")
    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    app.get_response(:get, "/service/#{service_manifest[:vendor]}/connection").body_str.should == data
  end
end
