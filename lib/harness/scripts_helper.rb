
# This module is included rspec configure block automatically
# Therefore, yeti dev do not include this module explicitly in xx_spec.rb file
module BVT::Harness
  module ScriptsHelper

    # Service
    def create_service(service_manifest, name=nil)
      service_name = name || service_manifest[:vendor]
      require_namespace = name.nil?
      service = @session.service(service_name, require_namespace)
      unless service.available?(service_manifest)
        @session.log.debug("Service: (#{service_manifest[:vendor]} #{service_manifest[:version]}) " +
                           "is not available on target: #{@session.TARGET}")
        pending("Service: (#{service_manifest[:vendor]} #{service_manifest[:version]}) " +
                    "is not available on target: #{@session.TARGET}")
      end
      service.create(service_manifest)
      service
    end

    def bind_service(service_manifest, app, name=nil)
      service = create_service(service_manifest, name)
      app.bind(service)
      service
    end

    # Application
    def create_app(app_name, prefix = '', domain=nil)
      app = @session.app(app_name, prefix, domain)
      app.load_manifest
      if VCAP_BVT_SYSTEM_FRAMEWORKS.has_key?(app.manifest['framework'].to_sym) &&
          VCAP_BVT_SYSTEM_RUNTIMES.has_key?(app.manifest['runtime'])
      else
        @session.log.debug("Runtime/Framework: #{app.manifest['runtime']}/#{app.manifest['framework']} " +
                         "is not available on target: #{@session.TARGET}")
        pending("Runtime/Framework: #{app.manifest['runtime']}/#{app.manifest['framework']} " +
                    "is not available on target: #{@session.TARGET}")
      end
      if app.manifest['path'].end_with?('.jar') || app.manifest['path'].end_with?('.war')
        pending "Package not found, please run update.sh" unless File.exist? app.manifest['path']
      end
      app
    end

    def create_push_app(app_name, prefix = '', domain=nil)
      app = create_app(app_name, prefix, domain)
      app.push
      unless @session.v2?
        app.healthy?.should be_true, "Application #{app.name} is not running"
      end
      app
    end
  end
end
