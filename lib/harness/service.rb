require "cfoundry"

module BVT::Harness
  class Service
    attr_reader :name, :instance

    def initialize(service, session)
      @instance = service
      @session = session
      @log = @session.log
      @name = @instance.name
    end

    def inspect
      "#<BVT::Harness::Service '#@name'>"
    end

    # service manifest example
    #{:vendor=>"mysql", :version=>"5.1"}
    def create(service_manifest)
      unless available?(service_manifest)
        @log.error("Service: #{service_manifest[:vendor]} #{service_manifest[:version]} " +
                       "is not available on target: #{@session.TARGET}")
        raise RuntimeError, "Service: #{service_manifest[:vendor]}" +
            " #{service_manifest[:version]} is not available on target: #{@session.TARGET}"
      end

      services = @session.client.services
      services.reject! { |s| s.provider != service_manifest[:provider] } if service_manifest[:provider]
      services.reject! { |s| s.version != service_manifest[:version] } if service_manifest[:version]

      service = services.first
      @log.debug("Prepare to create service: #{@instance.name}")
      begin
        if ENV['VCAP_BVT_SERVICE_PLAN']
          plan = ENV['VCAP_BVT_SERVICE_PLAN']
        elsif service_manifest[:plan]
          plan = service_manifest[:plan]
        else
          plan = @session.v2? ? "D100" : "free"
        end
        if @session.v2?
          plans = service.service_plans.select { |p| p.name == plan}
          plan = plans.first
          @instance.service_plan = plan
          @instance.space = @session.current_space
          instance_info = "#{service.label} #{service.version} " +
              "#{service.provider}"
        else
          @instance.type = service.type
          @instance.vendor = service.label
          @instance.version = service.version
          @instance.tier = plan
          instance_info = "#{@instance.vendor} #{@instance.version} #{@instance.tier}"
        end

        @log.info("Create Service (#{instance_info}): #{@instance.name}")
        @instance.create!
      rescue Exception => e
        @log.error("Fail to create service (#{instance_info}):" +
                       " #{@instance.name}\n#{e.to_s}")
        raise RuntimeError, "Fail to create service (#{instance_info}):" +
            " #{@instance.name}\n#{e.to_s}\n#{@session.print_client_logs}"
      end
    end

    def delete
      if @instance.exists?
        if @session.v2?
          plan = @instance.service_plan
          service = plan.service
          instance_info = "#{service.label} #{service.version} #{plan.name} #{service.provider}"
        else
          instance_info = "#{@instance.vendor} #{@instance.version} #{@instance.tier}"
        end
        @log.info("Delete Service (#{instance_info}): #{@instance.name}")
        begin
          @instance.delete!
        rescue Exception => e
          @log.error("Fail to delete service (#{instance_info}): #{@instance.name}\n#{e.to_s}")
          raise RuntimeError, "Fail to delete service (#{instance_info}): #{@instance.name}\n#{e.to_s}\n#{@session.print_client_logs}"
        end
      end
    end

    def available?(service_manifest)
      match = false

      VCAP_BVT_SYSTEM_SERVICES.each do |name, providers|
        next unless name =~ /#{service_manifest[:vendor]}/

        # if :provider is not set, 'core' is default value
        service_manifest[:provider] ||= "core"
        next unless providers.has_key?(service_manifest[:provider])

        meta = providers[service_manifest[:provider]]
        version = meta[:versions].find { |v|
          v =~ /#{service_manifest[:version]}/
        }
        next unless version

        ###default service plan
        #in v1, use 'free'; in v2, use 'D100' as default
        default_service_plan = @session.v2? ? "D100" : "free"
        service_manifest[:plan] ||= default_service_plan
        plan = meta[:plans].find { |p|
          p =~ /#{service_manifest[:plan]}/
        }
        next unless plan

        match = true
        break
      end

      match
    end
  end
end
