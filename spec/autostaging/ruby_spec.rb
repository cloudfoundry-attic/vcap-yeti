require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::AutoStagingHelper

describe "AutoStaging::Ruby" do

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    show_crashlogs
    @session.cleanup!
  end

  it "services autostaging", :mysql => true, :mongodb => true, :rabbitmq => true,
    :slow => true,
    :postgresql => true, :redis => true, :p1 => true do
    manifests = [MYSQL_MANIFEST, REDIS_MANIFEST, MONGODB_MANIFEST,
                     RABBITMQ_MANIFEST, POSTGRESQL_MANIFEST]
    app = create_push_app("app_sinatra_service_autoconfig", nil, nil, manifests)
    manifests.each do |service_manifest|
      verify_service_autostaging(service_manifest, app)
    end
  end

  it "Sinatra AMQP autostaging", :slow => true, :rabbitmq => true do
    service_manifest = RABBITMQ_MANIFEST
    app = push_app_and_verify("amqp_autoconfig", "/", "hello from sinatra", [service_manifest])
    # provision service
    data = "#{service_manifest[:vendor]}abc"
    app.get_response(:post, "/service/amqpurl/abc", data)
    app.get_response(:get, "/service/amqpurl/abc").to_str.should == data

    app.get_response(:post, "/service/amqpoptions/abc", data)
    app.get_response(:get, "/service/amqpoptions/abc").to_str.should == data
  end

  it "Autostaging with unsupported client versions", :mysql => true,
    :redis => true, :rabbitmq => true, :mongodb => true, :postgresql => true do
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
    service_manifests = testdata.map { |hash| hash[:service] }
    app = push_app_and_verify("autoconfig_unsupported_versions", "/",
                              "hello from sinatra", service_manifests)
    testdata.each do |item|
      verify_unsupported_client_version(item[:service], app, item[:data])
    end
  end

  it "Autostaging with unsupported carrot version", :rabbitmq => true do
    # provision service
    service_manifest = RABBITMQ_MANIFEST
    app = push_app_and_verify("autoconfig_unsupported_carrot_version", "/",
                              "hello from sinatra", [service_manifest])
    data = "Connectionrefused-connect(2)-127.0.0.1:1234"
    app.get_response(:get, "/service/carrot/connection").to_str.should == data
  end

  it "Ruby app with no URL", :mysql => true, :redis => true, :mongodb => true, :postgresql => true, :rabbitmq => true do
    # provision service
    manifests = [MYSQL_MANIFEST, REDIS_MANIFEST, MONGODB_MANIFEST,
                 RABBITMQ_MANIFEST, POSTGRESQL_MANIFEST]
    app = create_push_app("standalone_ruby18_autoconfig", nil, nil, manifests)

    manifests.each do |service_manifest|
      verify_service_autostaging(service_manifest, app)
    end
  end
end
