require "harness"

module BVT::Spec
  module AutoStagingHelper
    include BVT::Harness::HTTP_RESPONSE_CODE

    def verify_service_autostaging(service_manifest, app)
      key = "abc"
      data = "#{service_manifest[:vendor]}#{key}"
      url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
      response = app.get_response(:post, "/service/#{url}/#{key}", data)
      response.response_code.should equal(OK), "Response code should be #{OK}, " +
          "however got #{response.response_code}, and body is \n#{response.body_str}"
      app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
    end

    def verify_unsupported_client_version(service_manifest, app, data)
      key = "connection"
      url = SERVICE_URL_MAPPING_UNSUPPORTED_VERSION[service_manifest[:vendor]]
      app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
    end

    def push_app_and_verify(app_name, relative_url, response_str)
      app = create_app(app_name)
      app.push
      app.healthy?.should be_true, "Application #{app.name} is not running"
      app.get_response(:get, relative_url).body_str.should =~ /#{response_str}/
      app
    end

  end
end
