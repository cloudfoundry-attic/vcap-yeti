require "harness"

module BVT::Spec
  module CanonicalHelper
    include BVT::Harness::HTTP_RESPONSE_CODE

    def verify_service(service_manifest, app, key)
      data = "#{service_manifest[:vendor]}#{key}"
      url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
      app.get_response(:post, "/service/#{url}/#{key}", data)
      app.get_response(:get, "/service/#{url}/#{key}").to_str.should == data
    end

    def bind_service_and_verify(app, service_manifest)
      bind_service(service_manifest, app)
      verify_keys(app, service_manifest)
    end

    def verify_keys(app, service_manifest)
      %W(abc 123 def).each { |key| verify_service(service_manifest, app, key)}
    end

    def add_env(app, key, value)
      env = {"#{key}"=>"#{value}"}
      app.env = env
      app.update!
    end
  end
end
