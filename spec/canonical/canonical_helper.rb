require "harness"

module BVT::Spec
  module CanonicalHelper
    include BVT::Harness::HTTP_RESPONSE_CODE

    def verify_service(service_manifest, app, key)
      data = "#{service_manifest[:vendor]}#{key}"
      url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
      response = app.get_response(:post, "/service/#{url}/#{key}", data)
      response.response_code.should equal(OK), "Response code should be #{OK}, " +
          "however got #{response.response_code}, and body is \n#{response.body_str}"
      app.get_response(:get, "/service/#{url}/#{key}").body_str.should == data
    end

    def bind_service_and_verify(app, service_manifest)
      service = bind_service(service_manifest, app)
      %W(abc 123 def).each { |key| verify_service(service_manifest, app, key)}
    end

    def add_env(app, key, value)
      env = {"#{key}"=>"#{value}"}
      manifest = {}
      manifest['env'] = env
      app.update!(manifest)
    end
  end
end
