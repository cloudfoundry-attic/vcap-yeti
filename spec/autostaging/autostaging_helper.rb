

module BVT::Spec
  module AutoStagingHelper

    def bind_service(service_manifest, app)
      service = @session.service(service_manifest['vendor'])
      service.create(service_manifest)
      app.bind(service.name)
    end

    def verify_service_autostaging(service_manifest, app)
      key = "abc"
      data = "#{service_manifest['vendor']}#{key}"
      url = SERVICE_URL_MAPPING[service_manifest['vendor']]
      app.get_response(:post, "/service/#{url}/#{key}", data)
      app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
    end

    def create_service(service_manifest)
      service = @session.service(service_manifest['vendor'])
      service.create(service_manifest)
      service
    end

    def verify_unsupported_client_version(service_manifest, app, data)
      key = "connection"
      url = SERVICE_URL_MAPPING_UNSUPPORTED_VERSION[service_manifest['vendor']]
      app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
    end

  end
end