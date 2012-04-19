require "cfoundry"

module BVT::Harness
  class App
    attr_reader :name

    def initialize(app, session)
      @app = app
      @name = @app.name
      @session = session
      @log = @session.log
    end

    def inspect
      "#<BVT::Harness::App '#@name'>"
    end

    # manifest example
    #
    #{"instances"=>1,
    # "staging"=>{"framework"=>"sinatra", "runtime"=>"ruby19"},
    # "resources"=>{"memory"=>64}
    #}
    #
    def push(manifest)
      check_framework(manifest['staging']['framework'])
      check_runtime(manifest['staging']['runtime'])
      manifest['path'] = get_app_path
      manifest['uris'] = [get_url,]

      if @app.exists?
        @app.upload(manifest['path'])
        restart
        return
      end

      @app.total_instances = manifest['instances']
      @app.urls = manifest['uris']
      @app.framework = manifest['staging']['framework']
      @app.runtime = manifest['staging']['runtime']
      @app.memory = manifest['resources']['memory']

      @log.info "Push App: #{@app.name}"
      begin
        @app.create!
        @app.upload(manifest['path'])
      rescue
        @log.error("Push App: #{@app.name} failed. Manifest: #{manifest}")
        raise RuntimeError, "Push App: #{@app.name} failed. Manifest: #{manifest}"
      end

      start
    end

    def delete
      @log.info("Delete App: #{@app.name}")
      begin
        @app.delete!
      rescue
        @log.error "Delete App: #{@app.name} failed. "
        raise RuntimeError, "Delete App: #{@app.name} failed."
      end
    end

    def restart
      stop
      start
    end

    def stop
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError "Application: #{@app.name} does not exist!"
      end

      unless @app.stopped?
        @log.info "Stop App: #{@app.name}"
        begin
          @app.stop!
        rescue
          @log.error "Stop App: #{@app.name} failed. "
          raise RuntimeError, "Stop App: #{@app.name} failed."
        end
      end
    end

    def start
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError "Application: #{@app.name} does not exist!"
      end

      unless @app.running?
        @log.info "Start App: #{@app.name}"
        begin
          @app.start!
        rescue
          @log.error "Start App: #{@app.name} failed. "
          raise RuntimeError, "Start App: #{@app.name} failed."
        end
      end
      check_application
    end

    def bind(service_name)
      unless @session.services.collect(&:name).include?(service_name)
        @log.error("Fail to find service: #{service_name}")
        raise RuntimeError, "Fail to find service: #{service_name}"
      end
      begin
        @log.info("Application: #{@app.name} bind Service: #{service_name}")
        @app.bind(service_name)
        restart
      rescue
        @log.error("Fail to bind Service: #{service_name} to Application: #{@app.name}")
        raise RuntimeError, "Fail to bind Service: #{service_name} to Application: #{@app.name}"
      end
    end

    def unbind(service_name)
      unless @app.services.include?(service_name)
        @log.error("Fail to find service: #{service_name} binding to application: #{@app.name}")
        raise RuntimeError, "Fail to find service: #{service_name} binding to application: #{@app.name}"
      end

      begin
        @log.info("Application: #{@app.name} unbind Service: #{service_name}")
        @app.unbind(service_name)
        restart
      rescue
        @log.error("Fail to unbind service: #{service_name} for application: #{@app.name}")
        raise RuntimeError, "Fail to unbind service: #{service_name} for application: #{@app.name}"
      end
    end

    def healthy?
      @app.healthy?
    end

    # method should be REST method, only [:get, :put, :post] is supported
    def get_response(method, relative_path = "/", data = nil)
      unless [:get, :put, :post].include?(method)
        @log.error("REST method #{method} is not supported")
        raise RuntimeError, "REST method #{method} is not supported"
      end

      easy = Curl::Easy.new
      easy.url = get_url + relative_path
      easy.resolve_mode = :ipv4
      begin
        case method
          when :get
            @log.debug("Get response from URL: #{easy.url}")
            easy.http_get
          when :put
            @log.debug("Put data: #{data} to URL: #{easy.url}")
            easy.http_put(data)
          when :post
            @log.debug("Post data: #{data} to URL: #{easy.url}")
            easy.http_post(data)
          else nil
        end
        # Time dependency
        # Some app's post is async. Sleep to ensure the operation is done.
        sleep 0.1
        return easy
      rescue Exception => e
        @log.error("Cannot #{method} data from/to #{easy.url}\n#{e.to_s}")
        raise RuntimeError, "Cannot #{method} data from/to #{easy.url}\n#{e.to_s}"
      end
    end

    private

    APP_CHECK_LIMIT = 60

    def check_application
      seconds = 0
      until @app.healthy?
        sleep 1
        seconds += 1
        if seconds == APP_CHECK_LIMIT
          @log.error "Application: #{@app.name} cannot be started in #{APP_CHECK_LIMIT} seconds"
          raise RuntimeError, "Application: #{@app.name} cannot be started in #{APP_CHECK_LIMIT} seconds"
        end
      end
    end

    def check_framework(framework)
      if File.exists?(VCAP_BVT_PROFILE_FILE)
        @profile ||= YAML.load_file(VCAP_BVT_PROFILE_FILE)
        unless @profile.is_a?(Hash)
          @log.error("Invalid profile file format, #{VCAP_BVT_PROFILE_FILE}")
          raise "Invalid profile file format, #{VCAP_BVT_PROFILE_FILE}"
        end
        frameworks = @profile[:frameworks]
      end
      frameworks ||= @session.system_frameworks

      match = true if frameworks.has_key?(framework)

      unless match
        @log.error("Framework: #{framework} is not available on target: #{@session.TARGET}")
        pending("Framework: #{framework} is not available on target: #{@session.TARGET}")
      end

    end

    def check_runtime(runtime)
      if File.exists?(VCAP_BVT_PROFILE_FILE)
        @profile ||= YAML.load_file(VCAP_BVT_PROFILE_FILE)
        unless @profile.is_a?(Hash)
          @log.error("Invalid profile file format, #{VCAP_BVT_PROFILE_FILE}")
          raise "Invalid profile file format, #{VCAP_BVT_PROFILE_FILE}"
        end
        runtimes = @profile[:runtimes]
      end
      runtimes ||= @session.system_runtimes

      match = true if runtimes.has_key?(runtime)

      unless match
        @log.error("Runtime: #{runtime} is not available on target: #{@session.TARGET}")
        pending("Runtime: #{runtime} is not available on target: #{@session.TARGET}")
      end
    end

    def get_app_path
      app_config = YAML.load_file(VCAP_BVT_APP_CONFIG)
      unless app_config.is_a?(Hash)
        @log.error("Invalid config file format, #{VCAP_BVT_APP_CONFIG}")
        raise RuntimeError, "Invalid config file format, #{VCAP_BVT_APP_CONFIG}"
      end
      appid = @app.name.split('-', 2).last
      unless app_config.has_key?(appid)
        @log.error("Cannot find application #{appid} in #{VCAP_BVT_APP_CONFIG}")
        raise RuntimeError, "Cannot find application #{appid} in #{VCAP_BVT_APP_CONFIG}"
      end

      File.join(File.dirname(__FILE__), "../..", app_config[appid]['path'])
    end

    def get_url
      # URLs synthesized from app names containing '_' are not handled well by the Lift framework.
      # So we used '-' instead of '_'
      # '_' is not a valid character for hostname according to RFC 822,
      # use '-' to replace it.
      "#{@app.name}.#{@session.TARGET.gsub("http://api.", "")}".gsub("_", "-")
    end
  end
end
