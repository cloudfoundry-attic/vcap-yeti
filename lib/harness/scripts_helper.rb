
# This module is included rspec configure block automatically
# Therefore, yeti dev do not include this module explicitly in xx_spec.rb file
module BVT::Harness
  module ScriptsHelper

    # Service
    def create_service(service_manifest, name=nil)
      service_name = name || service_manifest[:vendor]

      time_block "create_service '#{service_name}'" do
        require_namespace = name.nil?
        service = @session.service(service_name, require_namespace)

        unless service.available?(service_manifest)
          msg = <<-MSG
            Service:
              #{service_manifest[:vendor]}
              #{service_manifest[:version]}
            is not available on target: #{@session.TARGET}
          MSG

          @session.log.debug(msg)
          pending(msg)
        end

        service.create(service_manifest)
        service
      end
    end

    def bind_service(service_manifest, app, name=nil)
      time_block "bind_service '#{app.name}'" do
        service = create_service(service_manifest, name)
        app.bind(service)
        service
      end
    end

    # Application
    def create_app(app_name, prefix = '', domain=nil)
      time_block "create_app '#{app_name}'" do
        app = @session.app(app_name, prefix, domain)
        app.load_manifest
        if app.manifest['path'].end_with?('.jar') || app.manifest['path'].end_with?('.war')
          pending "Package not found, please run update.sh" unless File.exist? app.manifest['path']
        end
        @current_app = app
        app
      end
    end

    def create_push_app(app_name, prefix = '', domain=nil, services=[])
      time_block "create_push_app '#{app_name}'" do
        app = create_app(app_name, prefix, domain)

        service_instances = services.map do |service|
          create_service(service)
        end

        app.push(service_instances)

        unless @session.v2?
          app.healthy?.should be_true, "Application #{app.name} is not running"
        end

        app
      end
    end

    def time_block(name)
      t = Time.new
      result = yield
      puts "Took %.5fs for #{name} to finish" % (Time.now - t)
      result
    end
  end
end
