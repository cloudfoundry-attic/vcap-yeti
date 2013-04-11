module BVT
  module Verification
    module Services
      def verify_keys(app, service_vendor)
        %W(abc 123 def).each { |key| verify_service(service_vendor, app, key)}
      end

      def verify_service(service_vendor, app, key)
        data = "#{rand}#{service_vendor}#{key}"
        app.get_response(:post, "/service/#{service_vendor}/#{key}", data)
        app.get_response(:get,  "/service/#{service_vendor}/#{key}").to_str.should == data
      end
    end
  end
end
