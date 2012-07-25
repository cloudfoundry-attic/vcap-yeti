require "cfoundry"

module BVT::Harness
  class Service
    attr_reader :name

    def initialize(service, session)
      @service = service
      @session = session
      @log = @session.log
      @name = @service.name
    end

    def inspect
      "#<BVT::Harness::Service '#@name'>"
    end
    # service manifest example
    #{:vendor=>"mysql", :version=>"5.1"}
    def create(service_manifest)
      unless has_vendor?(service_manifest)
        @log.error("Service: #{service_manifest[:vendor]} #{service_manifest[:version]} " +
                       "is not available on target: #{@session.TARGET}")
        raise RuntimeError, "Service: #{service_manifest[:vendor]}" +
            " #{service_manifest[:version]} is not available on target: #{@session.TARGET}"
      end

      @log.info("Create Service (#{@service.vendor} #{@service.version}): #{@service.name}")
      begin
        @service.create!
      rescue Exception => e
        @log.error("Fail to create service (#{@service.vendor} " +
                       "#{@service.version}): #{@service.name}\n#{e.to_s}")
        raise RuntimeError, "Fail to create service (#{@service.vendor} " +
            "#{@service.version}): #{@service.name}\n#{e.to_s}"
      end
    end

    def delete
      if @service.exists?
        @log.info("Delete Service (#{@service.vendor} " +
                      "#{@service.version}): #{@service.name}")
        begin
          @service.delete!
        rescue Exception => e
          @log.error("Fail to delete service (#{@service.vendor} " +
                         "#{@service.version}): #{@service.name}")
          raise RuntimeError, "Fail to delete service (#{@service.vendor} " +
              "#{@service.version}): #{@service.name}\n#{e.to_s}"
        end
      end
    end

    def has_vendor?(service_manifest)
      match = false

      VCAP_BVT_SYSTEM_SERVICES.each do |vendor, meta|
        next unless vendor =~ /#{service_manifest[:vendor]}/

        version = meta[:versions].find { |v|
          v =~ /#{service_manifest[:version]}/
        }
        next unless version

        @service.type = meta[:type]
        @service.vendor = vendor
        @service.version = version
        # TODO: only free service plan is supported
        @service.tier = "free"

        match = true
        break
      end

      match
    end
  end
end
