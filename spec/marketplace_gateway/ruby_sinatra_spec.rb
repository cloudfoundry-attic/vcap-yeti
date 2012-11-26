require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::MarketplaceGateway::RubySinatra do

  # Temporary function until yeti has support for provider
  def create_service_using_v1_api(manifest)
    target = ENV['VCAP_BVT_TARGET']
    base_url = target =~ /^http:\/\/api\./ ? target : "http://api.#{target}"
    client = ("#{base_url}/services/v1/offerings")

    provision_request = {
      :label => "#{manifest[:vendor]}-#{manifest[:version]}",
      :name => manifest[:name],
      :plan => manifest[:plan] || "free",
      :version => manifest[:version],
      :provider => manifest[:provider],
    }

    payload = Yajl::Encoder.encode(provision_request)

    headers = {}
    headers["Authorization"] = @session.token
    headers["Accept"] = "application/json"
    headers["Content-Type"] = "application/json"
    headers["Content-Length"] = payload.size

    req = {}
    req[:method]  = "post"
    req[:url]     = "#{base_url}/services/v1/configurations"
    req[:headers] = headers
    req[:payload] = payload

    RestClient::Request.execute(req) do |response, request|
      if response.code == 200
        @session.service(manifest[:name], false)
      else
        raise response.to_str
      end
    end
  end

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
    response.body_str.should =~ /^OK/
    response.response_code.should == 200
    response.close
  end

  it "should deploy env_test app and be able to bind to testservice from test mpgw" do
    uri = URI.parse(@mpgw_url)
    http = Net::HTTP.new(uri.host, uri.port)
    resp = http.request(
      Net::HTTP::Get.new("/",
        {'Content-Type' => 'application/json', 'X-VCAP-Service-Token' => @mpgw_token}))

    resp.code.should == "200"
    json = JSON.parse(resp.body)
    json["marketplace"].should == "Test"
    json["offerings"].keys.include?("testservice-1.0").should == true

    app = create_push_app("env_test_app")
    should_be_there = []

    myname = "testservice-12345"
    manifest = MPGW_TESTSERVICE_MANIFEST.dup

    # then record for testing against the environment variables
    manifest[:name] = myname

    service = create_service_using_v1_api(manifest) # TODO: Replace with yeti function

    app.bind(service)
    should_be_there << manifest

    services = app.services
    services.should_not == nil

    response = app.get_response(:get, '/services')
    response.should_not == nil
    response.response_code.should == 200
    service_list = JSON.parse(response.body_str)
    response.close

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
