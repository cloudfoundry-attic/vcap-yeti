require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::AutoStagingHelper

describe BVT::Spec::AutoStaging::RubyStandalone do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "standalone ruby18 autostaging", :mysql => true, :redis => true,
    :mongodb => true, :postgresql => true, :rabbitmq => true do
    app = create_push_app("standalone_ruby18_autoconfig")

    # provision service
    manifests = [MYSQL_MANIFEST, REDIS_MANIFEST, MONGODB_MANIFEST,
                 RABBITMQ_MANIFEST, POSTGRESQL_MANIFEST]
    manifests.each do |service_manifest|
      bind_service(service_manifest, app)
      verify_service_autostaging(service_manifest, app)
    end
  end

  it "standalone ruby opt-out of autostaging via config file", :redis => true do
    app = create_push_app("standalone_ruby_autoconfig_disabled_by_file")
    app.get_response(:get).to_str.should == "hello from sinatra"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    res = app.get_response(:get, "/service/#{service_manifest[:vendor]}/connection")
    res.to_str.should == data
  end

  it "standalone ruby opt-out of autostaging via cf-runtime gem", :redis => true do
    app = create_push_app("standalone_ruby_autoconfig_disabled_by_gem")
    app.get_response(:get).to_str.should == "hello from sinatra"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    res = app.get_response(:get, "/service/#{service_manifest[:vendor]}/connection")
    res.to_str.should == data
  end

end
