require "cfoundry"

module BVT::Harness
  class App
    attr_reader :name, :manifest

    def initialize(app, session, domain=nil)
      @app      = app
      @name     = @app.name
      @session  = session
      @client   = @session.client
      @log      = @session.log
      @domain      = domain
    end

    def inspect
      "#<BVT::Harness::App '#@name' '#@manifest'>"
    end

    def push(services = nil, appid = nil, need_check = true)
      load_manifest(appid)
      @app = @session.client.app_by_name(@name)
      if @app
        sync_app(@app, @manifest['path'])
      else
        create_app(@name, @manifest['path'], services, need_check)
      end
    end

    def delete
      @log.info("Delete App: #{@app.name}")
      begin
        if @session.v2?
          @app.routes.each do |r|
            @log.debug("Delete route #{r.name} from app: #{@app.name}")
            r.delete!
          end
        end
        @app.delete!
      rescue Exception => e
        @log.error "Delete App: #{@app.name} failed. "
        raise RuntimeError, "Delete App: #{@app.name} failed.\n#{e.to_s}\n#{@session.print_client_logs}"
      end
    end

    def routes
      begin
        @app.routes
      rescue Exception => e
        @log.error "Get routes failed. App: #{@app.name}"
        raise RuntimeError, "Get routes failed. App: #{@app.name}\n#{e.to_s}\n#{@session.print_client_logs}"
      end
    end

    def update!
      @log.info("Update App: #{@app.name}")
      begin
        @app.update!
        restart
      rescue Exception => e
        @log.error "Update App: #{@app.name} failed.\n#{e.to_s}"
        raise RuntimeError, "Update App: #{@app.name} failed.\n#{e.to_s}\n#{@session.print_client_logs}"
      end
    end

    def restart
      stop
      start
    end

    def stop
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end

      unless @app.stopped?
        @log.info "Stop App: #{@app.name}"
        begin
          @app.stop!
        rescue
          @log.error "Stop App: #{@app.name} failed. "
          raise RuntimeError, "Stop App: #{@app.name} failed.\n#{@session.print_client_logs}"
        end
      end
    end

    def start(need_check = true, async = false, &blk)
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end

      unless @app.running?
        @log.info "Start App: #{@app.name}"
        begin
          @app.start!(true, &blk)
        rescue Exception => e
          @log.error "Start App: #{@app.name} failed.\n#{e.to_s}"
          raise RuntimeError, "Start App: #{@app.name} failed.\n#{e.to_s}\n#{@session.print_client_logs}"
        end
        check_application if need_check
      end
    end

    def bind(service, restart_app = true)
      unless @session.services.collect(&:name).include?(service.name)
        @log.error("Fail to find service: #{service.name}")
        raise RuntimeError, "Fail to find service: #{service.name}"
      end
      begin
        @log.info("Application: #{@app.name} bind Service: #{service.name}")
        @app.bind(service.instance)
      rescue Exception => e
        @log.error("Fail to bind Service: #{service.name} to Application:" +
                       " #{@app.name}\n#{e.to_s}")
        raise RuntimeError, "Fail to bind Service: #{service.name} to " +
            "Application: #{@app.name}\n#{e.to_s}\n#{@session.print_client_logs}"
      end
      restart if restart_app
    end

    def unbind(service, restart_app = true)
      unless @app.services.collect(&:name).include?(service.name)
        @log.error("Fail to find service: #{service.name} binding to " +
                       "application: #{@app.name}")
        raise RuntimeError, "Fail to find service: #{service.name} binding to " +
            "application: #{@app.name}"
      end

      begin
        @log.info("Application: #{@app.name} unbind Service: #{service.name}")
        @app.unbind(service.instance)
        restart if restart_app
      rescue
        @log.error("Fail to unbind service: #{service.name} for " +
                       "application: #{@app.name}")
        raise RuntimeError, "Fail to unbind service: #{service.name} for " +
            "application: #{@app.name}\n#{@session.print_client_logs}"
      end
    end

    def stats
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end
      begin
        @log.info("Display application: #{@app.name} status")
        @app.stats
      rescue CFoundry::StatsError
	      "Application #{@app.name} is not running."
      end
    end

    def map(url)
      @log.info("Map URL: #{url} to Application: #{@app.name}.")
      simple = url.sub(/^https?:\/\/(.*)\/?/i, '\1')
      begin
        if @session.v2?
          host, domain_name = simple.split(".", 2)

          domain =
            @session.current_space.domain_by_name(domain_name, :depth => 0)

          unless domain
            @log.error("Invalid domain '#{domain_name}, please check your input url: #{url}")
            raise RuntimeError, "Invalid domain '#{domain_name}, please check your input url: #{url}"
          end

          route = @session.client.routes_by_host(host, :depth => 0).find do |r|
            r.domain == domain
          end

          unless route
            route = @session.client.route
            route.host = host
            route.domain = domain
            route.space = @session.current_space
            route.create!
          end

          @log.debug("Binding #{simple} to application: #{@app.name}")
          @app.add_route(route)
        else
          @app.urls << simple
          @app.update!
        end
      rescue Exception => e
        @log.error("Fail to map url: #{simple} to application: #{@app.name}!\n#{e.to_s}")
        raise RuntimeError, "Fail to map url: #{simple} to application: #{@app.name}!\n#{e.to_s}\n#{@session.print_client_logs}"
      end

      @log.debug("Application: #{@app.name}, URLs: #{@app.urls}")

    end

    def unmap(url, options={})
      @log.info("Unmap URL: #{url} to Application: #{@app.name}")
      simple = url.sub(/^https?:\/\/(.*)\/?/i, '\1')
      begin
        if @session.v2?
          host, domain_name = simple.split(".", 2)

          route = @app.routes.find do |r|
            r.host == host && r.domain.name == domain_name
          end

          unless route
            @log.error("Invalid route '#{simple}', please check your input url: #{url}")
            raise RuntimeError, "Invalid route '#{simple}', please check your input url: #{url}"
          end

          @log.debug("Removing route #{simple}")
          @app.remove_route(route)
          route.delete! if options[:delete]
        else
          @app.urls.delete(simple)
          @app.update!
        end
      rescue Exception => e
        @log.error("Fail to unmap url: #{simple} to application: #{@app.name}!\n#{e.to_s}")
        raise RuntimeError, "Fail to unmap url: #{simple} to application: #{@app.name}!\n#{e.to_s}\n#{@session.print_client_logs}"
      end
      @log.debug("Application: #{@app.name}, URLs: #{@app.urls}")
    end

    def urls
      @log.debug("List URLs: #{@app.urls} of Application: #{@app.name}")
      @app.urls
    end

    def files(path)
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end
      begin
        @log.info("Examine an application: #{@app.name} files")
        @app.files(path)
      rescue Exception => e
        @log.error("Fail to examine an application: #{@app.name} files!\n#{e.to_s}")
        raise RuntimeError, "Fail to examine an application: #{@app.name} files!\n#{e.to_s}\n#{@session.print_client_logs}"
      end
    end

    def file(path)
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end
      begin
        @log.info("Examine an application: #{@app.name} file")
        @app.file(path)
      rescue Exception => e
        @log.error("Fail to examine an application: #{@app.name} file!\n#{e.to_s}")
        raise RuntimeError, "Fail to examine an application: #{@app.name} file!\n#{e.to_s}\n#{@session.print_client_logs}"
      end
    end

    def scale(instance, memory)
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end
      begin
        @log.info("Update the instances/memory: #{instance}/#{memory} " +
                      "for Application: #{@app.name}")
        @app.total_instances = instance.to_i
        @app.memory = memory
        @app.update!
      rescue
        @log.error("Fail to Update the instances/memory limit for " +
                   "Application: #{@app.name}!")
        raise RuntimeError, "Fail to update the instances/memory limit for " +
                   "Application: #{@app.name}!\n#{@session.print_client_logs}"
      end
    end

    def instances
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end
      begin
        @log.debug("Get application: #{@app.name} instances list")
        @app.instances
      rescue
        @log.error("Fail to list the instances for Application: #{@app.name}!")
        raise RuntimeError, "Fail to list the instances for Application: #{@app.name}!\n#{@session.print_client_logs}"
      end
    end

    def total_instances=(val)
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end
      begin
        @log.debug("Set application: #{@app.name} total instances #{val}")
        @app.total_instances = val
      rescue
        @log.error("Fail to set the total instances for Application: #{@app.name}!")
        raise RuntimeError, "Fail to set the total instances for Application: #{@app.name}!\n#{@session.print_client_logs}"
      end
    end

    def total_instances
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end
      begin
        @log.debug("Get application: #{@app.name} total instances")
        @app.total_instances
      rescue
        @log.error("Fail to get the total instances for Application: #{@app.name}!")
        raise RuntimeError, "Fail to get the total instances for Application: #{@app.name}!\n#{@session.print_client_logs}"
      end
    end

    def env
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end
      begin
        @log.debug("Get application: #{@app.name} env")
        @app.env
      rescue
        @log.error("Fail to get the env for Application: #{@app.name}!")
        raise RuntimeError, "Fail to get the env for Application: #{@app.name}!\n#{@session.print_client_logs}"
      end
    end

    def env=(val)
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end
      begin
        @log.debug("Set application: #{@app.name} env #{val}")
        @app.env = val
      rescue
        @log.error("Fail to set the env for Application: #{@app.name}!")
        raise RuntimeError, "Fail to set the env for Application: #{@app.name}!\n#{@session.print_client_logs}"
      end
    end

    def services
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end
      begin
        @log.debug("Get application: #{@app.name} services list")
        @app.services
      rescue
        @log.error("Fail to list the services for Application: #{@app.name}!")
        raise RuntimeError, "Fail to list the services for Application: #{@app.name}!\n#{@session.print_client_logs}"
      end
    end

    # only retrieve logs of instance #0
    def logs
      unless @app.exists?
        @log.error "Application: #{@app.name} does not exist!"
        raise RuntimeError, "Application: #{@app.name} does not exist!"
      end

      begin
        instance = @app.instances[0]
        body = ""
        instance.files("logs").each do |log|
          body += instance.file(*log)
        end
      rescue Exception => e
        @log.error("Fail to get logs for Application: #{@app.name}!")
        raise RuntimeError, "Fail to get logs for Application: #{@app.name}!" +
            "\n#{e.to_s}\n#{@session.print_client_logs}"
      end
      @log.debug("Get Application #{@app.name}, logs contents: #{body}")
      body
    end

    def crashlogs
      @app.crashes.each do |instance|
        instance.files("logs").each do |logfile|
          content = instance.file(*logfile)
          unless content.empty?
            puts "\n======= Crashlogs: #{logfile.join("/")} ======="
            puts content
            puts "=" * 80
          end
        end
      end
    rescue CFoundry::FileError
      # Could not get crash logs
    end

    def healthy?
      h = @app.healthy?
      unless h
        sleep(0.1)
        h = @app.healthy?
      end
      h
    end

    # method should be REST method, only [:get, :put, :post, :delete] is supported
    def get_response(method, relative_path = "/", data = '', second_domain = nil, timeout = nil)
      unless [:get, :put, :post, :delete].include?(method)
        @log.error("REST method #{method} is not supported")
        raise RuntimeError, "REST method #{method} is not supported"
      end

      path = relative_path.start_with?("/") ? relative_path : "/" + relative_path

      url = get_url(second_domain) + path
      begin
        resource = RestClient::Resource.new(url, :timeout => timeout, :open_timeout => timeout)
        case method
          when :get
            @log.debug("Get response from URL: #{url}")
            r = resource.get
          when :put
            @log.debug("Put data: #{data} to URL: #{url}")
            r = resource.put data
          when :post
            @log.debug("Post data: #{data} to URL: #{url}")
            r = resource.post data
          when :delete
            @log.debug("Delete URL: #{url}")
            r = resource.delete
          else nil
        end
        # Time dependency
        # Some app's post is async. Sleep to ensure the operation is done.
        sleep 0.1
        return r
      rescue RestClient::Exception => e
        begin
          RestResult.new(e.http_code, e.http_body)
        rescue
          @log.error("Cannot #{method} response from/to #{url}\n#{e.to_s}")
          raise RuntimeError, "Cannot #{method} response from/to #{url}\n#{e.to_s}"
        end
      end
    end

    def load_manifest(appid = nil)
      if !@manifest || appid
        unless VCAP_BVT_APP_ASSETS.is_a?(Hash)
          @log.error("Invalid config file format, #{VCAP_BVT_APP_CONFIG}")
          raise RuntimeError, "Invalid config file format, #{VCAP_BVT_APP_CONFIG}"
        end
        appid ||= @app.name.split('-', 2).last

        unless VCAP_BVT_APP_ASSETS.has_key?(appid)
          @log.error("Cannot find application #{appid} in #{VCAP_BVT_APP_CONFIG}")
          raise RuntimeError, "Cannot find application #{appid} in #{VCAP_BVT_APP_CONFIG}"
        end

        app_manifest = VCAP_BVT_APP_ASSETS[appid].dup
        app_manifest['instances'] = 1 unless app_manifest['instances']
        app_manifest['path']      =
            File.join(File.dirname(__FILE__), "../..", app_manifest['path'])

        @manifest = app_manifest
      end
    end

    def get_url(second_domain = nil)
      # URLs synthesized from app names containing '_' are not handled well
      # by the Lift framework.
      # So we used '-' instead of '_'
      # '_' is not a valid character for hostname according to RFC 822,
      # use '-' to replace it.
      second_domain = "-#{second_domain}" if second_domain
      "#{@name}#{second_domain}.#{@session.TARGET.gsub(/http[s]?:\/\/\w+\./, "")}".gsub("_", "-")
    end

    def check_application
      # Wait initially since app most likely
      # will not complete staging and start under 10secs
      sleep(seconds = 10)

      until application_is_really_running?
        sleep 1
        seconds += 1

        if seconds == VCAP_BVT_APP_ASSETS['timeout_secs']
          @log.error \
            "Application: #{@app.name} cannot be started " +
            "in #{VCAP_BVT_APP_ASSETS['timeout_secs']} seconds"

          raise RuntimeError, \
            "Application: #{@app.name} cannot be started " +
            "in #{VCAP_BVT_APP_ASSETS['timeout_secs']} seconds.\n" +
            "#{@session.print_client_logs}"
        end
      end
    end

    def application_is_really_running?
      instances_are_all_running? && instances_are_all_running_for_a_bit?
    end

    def instances_are_all_running_for_a_bit?
      3.times.map {
        sleep(1)
        instances_are_all_running?
      }.all?
    end

    def instances_are_all_running?
      instances = @app.instances
      instances.map(&:state).uniq == ["RUNNING"]
    rescue CFoundry::Timeout => e
      false
    end

    def sync_app(app, path)
      upload_app(app, path)

      diff = {}

      mem = @manifest['memory']
      if mem != app.memory
        diff[:memory] = [app.memory, mem]
        app.memory = mem
      end

      instances = @manifest['instances']
      if instances != app.total_instances
        diff[:instances] = [app.total_instances, instances]
        app.total_instances = instances
      end

      command = @manifest['command']
      if command != app.command
        diff[:command] = [app.command, command]
        app.command = command
      end

      if @session.v2?
        production = @manifest['plan'] ? true : false

        if production != app.production
          diff[:production] = [app.production, production]
          app.production = production
        end
      end

      unless diff.empty?
        diff.each do |name, change|
          old, new = change
          @log.debug("Application: #{app.name}, Change: #{old} -> #{new}")
        end
        begin
          app.update!
        rescue Exception => e
          @log.error("Fail to update Application: #{app.name}\n#{e.inspect}")
          raise RuntimeError, "Fail to update Application: #{app.name}\n#{e.inspect}"
        end
      end
      restart
    end

    def create_app(name, path, services, need_check)
      app = @session.client.app
      app.name = name
      app.space = @session.current_space if @session.current_space
      app.total_instances = @manifest['instances']
      app.production = @manifest['plan'] if @session.v2? && @manifest['plan']

      app.command = @manifest['command']

      if @domain
        url = "#{@name}.#{@domain}"
      else
        url = get_url
      end

      @manifest['uris'] = [url,]

      app.memory = @manifest['memory']
      begin
        app.create!
      rescue Exception => e
        @log.error("Fail to create Application: #{app.name}\n#{e.inspect}")
        raise RuntimeError, "Fail to create Application: #{app.name}\n#{e.inspect}"
      end

      @app = app

      map(url) if !@manifest['no_url']

      services.each { |service| bind(service, false)} if services
      upload_app(app, path)

      start(need_check) unless @manifest["no_start"]
    end

    def upload_app(app, path)
      begin
        app.upload(path)
      rescue Exception => e
        @log.error("Fail to push/upload file path: #{path} for Application: #{app.name}\n#{e.inspect}")
        raise RuntimeError, "Fail to push/upload file path: #{path} for Application: #{app.name}\n#{e.inspect}"
      end
    end

  end

  class RestResult
    attr_reader :code
    attr_reader :to_str

    def initialize(code, to_str)
      @code = code
      @to_str = to_str
    end
  end
end
