require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::AutoStagingHelper

describe "AutoStaging::RubyRack" do

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
end
