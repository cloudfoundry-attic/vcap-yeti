require "uri"
require "json"
require "harness"
require "spec_helper"
require "services/service_broker_helper"
include BVT::Spec

describe "ServiceBroker" do
  include BVT::Spec::ServiceBrokerHelper
  BROKER_APP_VERSION = "9.99"

  before(:all) do
    check_env
  end

  after(:each) do
    show_crashlogs
    @session.cleanup! if @session
    cleanup
  end

  def init_brokered_service(app)
    brokered_service_app = app
    @bsvc_name = "simple_kv"
    @bsvc_version = BROKER_APP_VERSION
    @app_label = "#{@bsvc_name}-#{@bsvc_version}"
    @bsvc_plan = "default"
    #TODO remove the hardcode provider==name setup
    @bsvc_provider = @bsvc_name
    @option_name = "default"

    #the real name in vmc
    @brokered_service_name = "#{@bsvc_name}_#{@option_name}"
    @brokered_service_label = "#{@bsvc_name}_#{@option_name}-#{@bsvc_version}"
    app_uri = get_uri(brokered_service_app)
    @brokered_service = {
      :label => @app_label,
      :options => [ {
        :name => @option_name,
        :acls => {
          :users => [@session.email],
          :wildcards => []
        },
        :credentials =>{:url => "http://#{app_uri}"},
        :provider => @bsvc_provider,
      }]
    }
    @service_name = "brokered_service_app_#{@brokered_service_name}"
    @service_manifest = {
     :vendor => @brokered_service_name,
     :tier => "free",
     :version => BROKER_APP_VERSION,
     :plan => @bsvc_plan,
     :name => @service_name,
     :provider => @bsvc_provider,
    }
  end

  def cleanup
    delete_brokered_services @brokered_service if @brokered_service
    if @brokered_service_name && @bsvc_provider
      delete_service_auth_token(@brokered_service_name, @bsvc_provider)
    end
  end

  def post_and_verify_service(app,key,value)
    uri = get_uri(app, "brokered-service/#{@brokered_service_label}")
    data = "#{key}:#{value}"
    r = RestClient.post uri, data
    r.code.should == 200
  end

  def get_uri app, relative_path=nil
    uri = app.get_url
    if relative_path != nil
      uri << "/#{relative_path}"
    end
    uri
  end

  it "Create a brokered service" do
    setup
    app = create_push_app('simple_kv_app')
    init_brokered_service(app)
    cleanup
    create_service_auth_token(@brokered_service_name, @bsvc_provider)
    create_brokered_services @brokered_service
    app.services.should_not == nil

    brokered_app = create_push_app('brokered_service_app')
    bind_brokered_service(brokered_app, @service_manifest)
    post_and_verify_service(brokered_app,'key1','value1')

    content = app.get_response(:get, "/service/key1")
    content.should_not == nil
    content.code.should == 200
    content.to_str.should == 'value1'
  end

end
