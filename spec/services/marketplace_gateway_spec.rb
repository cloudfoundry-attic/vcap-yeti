require "harness"
require "spec_helper"
require "harness/rake_helper"

include BVT::Spec
include BVT::Harness::RakeHelper

describe "MarketplaceGateway" do

  before(:all) do
    @mpgw_url = ENV['MPGW_URL']
    @mpgw_token = ENV['MPGW_TOKEN']

    pending "test marketplace gateway url (MPGW_URL) or token (MPGW_TOKEN) not provided" unless @mpgw_url && @mpgw_token

    @session = BVT::Harness::CFSession.new
    @services = @session.system_services
  end

  after(:each) do
    @session.cleanup!
  end

  def health_check(app)
    response = app.get_response(:get, '/healthcheck')
    response.should_not == nil
    response.to_str.should =~ /^OK/
    response.code.should == 200
  end

  it "should deploy env_test app and be able to bind to testservice from test mpgw" do
    app = create_push_app("env_test_app")
    should_be_there = []

    myname = "testservice-12345"
    manifest = MPGW_TESTSERVICE_MANIFEST.dup
    service = create_service(manifest, myname)

    # then record for testing against the environment variables
    manifest[:name] = myname
    should_be_there << manifest

    app.bind(service)
    services = app.services
    services.should_not == nil

    response = app.get_response(:get, '/services')
    response.should_not == nil
    response.code.should == 200
    service_list = JSON.parse(response.to_str)

    # assert that the services list that we get from the app environment
    # matches what we expect from provisioning
    services = service_list['services']

    should_be_there.all? { |v|
      services.any? {|s|
        v[:name] == s['name'] && v[:vendor] == s['vendor']
      }
    }.should == true

    health_check(app)
  end

end
