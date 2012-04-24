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
    #{"vendor"=>"mysql", "version"=>"5.1"}
    def create(service_manifest)
      if File.exists?(VCAP_BVT_PROFILE_FILE)
        @profile ||= YAML.load_file(VCAP_BVT_PROFILE_FILE)
        unless @profile.is_a?(Hash)
          @log.error("Invalid profile file format, #{VCAP_BVT_PROFILE_FILE}")
          raise "Invalid profile file format, #{VCAP_BVT_PROFILE_FILE}"
        end
        services = @profile[:services]
      end
      services ||= @session.system_services
      match = false
      services.each do |type, vendors|
        vendors.each do |vendor, versions|
          versions.each do |version, _|
            if vendor =~ /#{service_manifest['vendor']}/ &&
                version =~ /#{service_manifest['version']}/
              match = true
              @service.type = type
              @service.vendor = vendor
              @service.version = version
              # TODO: only free service plan is supported
              @service.tier = "free"
              break
            end
          end
          break if match
        end
      end

      unless match
        @log.error("Service: #{service_manifest['vendor']} #{service_manifest['version']} " +
                       "is not available on target: #{@session.TARGET}")
        pending("Service: #{service_manifest['vendor']} #{service_manifest['version']} " +
                  "is not available on target: #{@session.TARGET}")
      end

      @log.info("Create Service (#{@service.vendor} #{@service.version}): #{@service.name}")
      begin
        @service.create!
      rescue Exception => e
        @log.error("Fail to create service (#{@service.vendor} " +
                       "#{@service.version}): #{@service.name}")
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
  end
end
