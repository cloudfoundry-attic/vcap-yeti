module BVT::Spec
  module CanonicalHelper

    def verify_service(service_manifest, app, key)
      data = "#{service_manifest['vendor']}#{key}"
      url = SERVICE_URL_MAPPING[service_manifest['vendor']]
      app.get_response(:post, "/service/#{url}/#{key}", data)
      app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
    end

    def bind_service_and_verify(app, service_manifest)
      service = bind_service(service_manifest, app)
      %W(abc 123 def).each { |key| verify_service(service_manifest, app, key)}
      app.unbind(service.name)
    end
  end
end
