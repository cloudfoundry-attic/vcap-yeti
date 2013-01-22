require "uri"

module BVT::Spec
  module ServiceBrokerHelper
    BROKER_API_VERSION = "v1"

    def check_env
      required_env_vars = %w(SERVICE_BROKER_TOKEN SERVICE_BROKER_URL VCAP_BVT_ADMIN_USER_PASSWD)
      required_env_vars.each do |env|
        pending "#{env} is not set." unless ENV[env] && !ENV[env].empty?
      end
    end

    def setup
      @session = BVT::Harness::CFSession.new
      @client = @session.client
      @service_broker_token = ENV['SERVICE_BROKER_TOKEN']
      @service_broker_url = ENV['SERVICE_BROKER_URL']
      @admin_session = BVT::Harness::CFSession.new(:admin => true)
      @admin_client = @admin_session.client
    end

    def broker_hdrs
      {
        'Content-Type' => 'application/json',
        'X-VCAP-Service-Token' => @service_broker_token,
      }
    end

    def create_brokered_services services
      klass = Net::HTTP::Post
      url = "/service-broker/#{BROKER_API_VERSION}/offerings"
      body = services.to_json
      resp = perform_http_request(klass, url, body)
      resp.code.should == "200"
    end

    def delete_brokered_services services
      klass = Net::HTTP::Delete
      label = services[:label]
      url = "/service-broker/#{BROKER_API_VERSION}/offerings/#{label}"
      resp = perform_http_request(klass, url)
      resp
    end

    def perform_http_request(klass, url, body=nil)
      uri = URI.parse(@service_broker_url)
      req = klass.new(url, initheader=broker_hdrs)
      req.body = body if body
      resp = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req)}
    end


    def bind_brokered_service(app, service_manifest)
      service_name = service_manifest[:name]
      service = @session.service(service_name, false)
      service.create(service_manifest, false)
      app.bind(service)

      health = app.healthy?
      health.should be_true
    end

    def create_service_auth_token(label, provider)
      return unless @admin_session.v2?

      sat = @admin_client.service_auth_token
      sat.label = label
      sat.provider = provider
      sat.token = @service_broker_token
      sat.create!
    end

    def delete_service_auth_token(label, provider)
      return unless @admin_session.v2?

      sats = @admin_client.service_auth_tokens
      sats.each do |sat|
        sat.delete! if sat.provider == provider && sat.label == label
      end
    end
  end
end

