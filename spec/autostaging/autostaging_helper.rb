

module BVT::Spec
  module AutoStagingHelper

    def verify_service_autostaging(service_manifest, app)
      key = "abc"
      data = "#{service_manifest[:vendor]}#{key}"
      url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
      app.get_response(:post, "/service/#{url}/#{key}", data)
      app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
    end

    def verify_unsupported_client_version(service_manifest, app, data)
      key = "connection"
      url = SERVICE_URL_MAPPING_UNSUPPORTED_VERSION[service_manifest[:vendor]]
      app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
    end

  end
end