require "uri"
require "json"
require "harness"
require "spec_helper"
include BVT::Spec

module BVT::Spec
  module ServiceBrokerHelper

  def new
    @service_broker_token = ENV['SERVICE_BROKER_TOKEN']
    @service_broker_url = ENV['SERVICE_BROKER_URL']
    pending "service broker url or token is not provided" unless @service_broker_url && @service_broker_token
  end

  BROKER_API_VERSION = "v1"
  BROKER_APP_VERSION = "9.99"

  def broker_hdrs
    {
    'Content-Type' => 'application/json',
    'X-VCAP-Service-Token' => @service_broker_token,
    }
  end

  def init_brokered_service(app)
    brokered_service_app = app
    app_name = "simple_kv"
    app_version = BROKER_APP_VERSION
    app_label = "#{app_name}-#{app_version}"
    option_name = "default"

    #the real name in vmc
    @brokered_service_name = "#{app_name}_#{option_name}"
    @brokered_service_label = "#{app_name}_#{option_name}-#{app_version}"
    app_uri = get_uri(brokered_service_app)
    @brokered_service = {
      :label => app_label,
      :options => [ {
        :name => option_name,
        :acls => {
          :users => [@session.email],
          :wildcards => []
        },
       :credentials =>{:url => "http://#{app_uri}"}
      }]
    }
    @service_name = "brokered_service_app_#{@brokered_service_name}"
    @service_manifest = {
     :vendor => "brokered_service",
     :tier => "free",
     :version => BROKER_APP_VERSION,
     :plan => "default",
     :name => @service_name
    }
  end

  def create_brokered_service(app)
    klass = Net::HTTP::Post
    url = "/service-broker/#{BROKER_API_VERSION}/offerings"
    body = @brokered_service.to_json
    resp = perform_http_request(klass, url, body)
    resp.code.should == "200"
  end

  def find_service(app,vendor)
    services = @session.system_services
    services.has_key?(vendor)
  end

  def find_brokered_service(app)
    find_service(app,@brokered_service_name)
  end

  def perform_http_request(klass, url, body=nil)
    uri = URI.parse(@service_broker_url)
    req = klass.new(url, initheader=broker_hdrs)
    req.body = body if body
    resp = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req)}
  end

  def get_uri app, relative_path=nil
    uri = app.get_url
    if relative_path != nil
      uri << "/#{relative_path}"
    end
    uri
  end

  def bind_brokered_service(app)
    service = @session.service(@service_name, false)
    service.create(@service_manifest, false)
    app.bind(service)

    health = app.healthy?
    health.should be_true
  end

  def post_and_verify_service(app,key,value)
    uri = get_uri(app, "brokered-service/#{@brokered_service_label}")
    data = "#{key}:#{value}"
    r = RestClient.post uri, data
    r.code.should == 200
  end

  def delete_brokered_services
    klass = Net::HTTP::Delete
    label = @brokered_service[:label]
    url = "/service-broker/#{BROKER_API_VERSION}/offerings/#{label}"
    resp = perform_http_request(klass, url)
    resp
  end

  end
end

describe BVT::Spec::ServiceBroker::RubySinatra do
  include BVT::Spec::ServiceBrokerHelper

  before(:all) do
    @session = BVT::Harness::CFSession.new
    @client = @session.client
    new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Create a brokered service" do
    app = create_push_app('simple_kv_app')
    init_brokered_service(app)
    delete_brokered_services
    create_brokered_service(app)

    app.services.should_not == nil
    # can't find service in ccng system_services
    # response = find_brokered_service(app)
    # response.should be_true

    brokered_app = create_push_app('brokered_service_app')
    bind_brokered_service(brokered_app)
    post_and_verify_service(brokered_app,'key1','value1')

    content = app.get_response(:get, "/service/key1")
    content.should_not == nil
    content.code.should == 200
    content.to_str.should == 'value1'
  end

end
