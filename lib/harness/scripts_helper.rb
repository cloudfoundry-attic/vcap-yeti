
# This module is included rspec configure block automatically
# Therefore, yeti dev do not include this module explicitly in xx_spec.rb file
module BVT::Harness
  module ScriptsHelper

    # Service
    def create_service(service_manifest)
      service = @session.service(service_manifest['vendor'])
      unless service.has_vendor?(service_manifest)
        pending("Service: (#{service_manifest['vendor']} #{service_manifest['version']}) " +
                    "is not available on target: #{@session.TARGET}")
      end
      service.create(service_manifest)
      service
    end

    def bind_service(service_manifest, app)
      service = create_service(service_manifest)
      app.bind(service.name)
    end

    # Application
    def create_app(app_name)
      app = @session.app(app_name)
      app.load_manifest
      if VCAP_BVT_SYSTEM_FRAMEWORKS.has_key?(app.manifest['framework']) &&
          VCAP_BVT_SYSTEM_RUNTIMES.has_key?(app.manifest['runtime'])
        app
      else
        pending("Runtime/Framework: #{app.manifest['runtime']}/#{app.manifest['framework']} " +
                    "is not available on target: #{@session.TARGET}")
      end
    end
  end
end
