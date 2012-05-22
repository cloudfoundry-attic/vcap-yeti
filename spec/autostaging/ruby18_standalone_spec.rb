require "harness"
require "spec_helper"

describe BVT::Spec::AutoStaging::Ruby18Standalone do
  include BVT::Spec
  include BVT::Spec::AutoStagingHelper

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "standalone ruby18 autostaging" do
    app = create_push_app("standalone_ruby18_autoconfig")

    # provision service
    manifests = [MYSQL_MANIFEST, REDIS_MANIFEST, MONGODB_MANIFEST,
                 RABBITMQ_MANIFEST, POSTGRESQL_MANIFEST]
    manifests.each do |service_manifest|
      bind_service(service_manifest, app)
      verify_service_autostaging(service_manifest, app)
    end
  end

  it "standalone ruby opt-out of autostaging via config file" do
    app = create_push_app("standalone_ruby_autoconfig_disabled_by_file")
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    res = app.get_response(:get, "/service/#{service_manifest['vendor']}/connection")
    res.body_str.should == data
  end

  it "standalone ruby opt-out of autostaging via cf-runtime gem" do
    app = create_push_app("standalone_ruby_autoconfig_disabled_by_gem")
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    res = app.get_response(:get, "/service/#{service_manifest['vendor']}/connection")
    res.body_str.should == data
  end

end
