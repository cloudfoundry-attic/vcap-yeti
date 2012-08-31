require "cfoundry"

module BVT::Harness
  class Service
    attr_reader :name, :instance

    def initialize(service, session)
      @instance = service
      @instance.name = @instance.inspect.scan(/'(.*)'/).first.first
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
      @log.info("Create Service (#{service.label} #{service.version}): #{@instance.name}")
      begin
        if @session.v2?
          if service_manifest[:plan]
            plans = service.service_plans.select { |p| p.name == service_manifest[:plan]}
            @instance.service_plan = plans.first
          end
          @instance.space = @session.client.current_space
        else
          @instance.type = service.type
          @instance.vendor = service.label
          @instance.version = service.version
          @instance.tier = "free"
        end
        @instance.create!
      rescue Exception => e
        @log.error("Fail to create service (#{service.label} " +
                       "#{service.version}): #{@instance.name}\n#{e.to_s}")
        raise RuntimeError, "Fail to create service (#{service.label} " +
            "#{service.version}): #{@instance.name}\n#{e.to_s}"
      end
    end

    def delete
      if @instance.exists?
        ## FIXME, CFoundry::V2::ServiceInstance did not support vendor, version attribute

        @log.info("Delete Service (): #{@instance.name}")
        begin
          @instance.delete!
        rescue Exception => e
          @log.error("Fail to delete service (): #{@instance.name}\n#{e.to_s}")
          raise RuntimeError, "Fail to delete service (): #{@instance.name}\n#{e.to_s}"
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

        service_manifest[:plan] ||= "free"
        plan = meta[:plans].find { |p|
          p =~ /#{service_manifest[:plan]}/
        }
        next unless plan

        #
        #@instance.type = meta[:type]
        #@instance.vendor = vendor
        #@instance.version = version
        ## TODO: only free service plan is supported
        #@instance.tier = "free"
        match = true
        break
      end

      match
    end
  end
end
