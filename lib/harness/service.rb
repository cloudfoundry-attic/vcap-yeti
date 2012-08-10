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
      unless has_vendor?(service_manifest)
        @log.error("Service: #{service_manifest[:vendor]} #{service_manifest[:version]} " +
                       "is not available on target: #{@session.TARGET}")
        raise RuntimeError, "Service: #{service_manifest[:vendor]}" +
            " #{service_manifest[:version]} is not available on target: #{@session.TARGET}"
      end

      @log.info("Create Service (#{@instance.vendor} #{@instance.version}): #{@instance.name}")
      begin
        @instance.create!
      rescue Exception => e
        @log.error("Fail to create service (#{@instance.vendor} " +
                       "#{@instance.version}): #{@instance.name}\n#{e.to_s}")
        raise RuntimeError, "Fail to create service (#{@instance.vendor} " +
            "#{@instance.version}): #{@instance.name}\n#{e.to_s}"
      end
    end

    def delete
      if @instance.exists?
        @log.info("Delete Service (#{@instance.vendor} " +
                      "#{@instance.version}): #{@instance.name}")
        begin
          @instance.delete!
        rescue Exception => e
          @log.error("Fail to delete service (#{@instance.vendor} " +
                         "#{@instance.version}): #{@instance.name}")
          raise RuntimeError, "Fail to delete service (#{@instance.vendor} " +
              "#{@instance.version}): #{@instance.name}\n#{e.to_s}"
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

        @instance.type = meta[:type]
        @instance.vendor = vendor
        @instance.version = version
        # TODO: only free service plan is supported
        @instance.tier = "free"

        match = true
        break
      end

      match
    end
  end
end
