require "cfoundry"
require "vcap/logging"

module BVT::Harness
  class CFSession
    attr_reader :log, :namespace, :TARGET, :email, :passwd, :is_admin, :token, :current_organization, :current_space

    def initialize(options = {})
      options = {:admin => false,
                 :email => nil,
                 :passwd => nil,
                 :target => nil}.merge(options)
      @is_admin = options[:admin]
      @email = options[:email] ? options[:email] : get_login_email(@is_admin)
      @passwd = options[:passwd] ? options[:passwd] : get_login_passwd(@is_admin)
      domain_url = options[:target] ? options[:target] : get_target

      #hard code for ccng
      case domain_url
        when /^ccng.*|^api.*/
          @TARGET = "http://#{domain_url}"
        when /^http[s]?:\/\/.*/
          @TARGET = domain_url
        else
          @TARGET = "http://api.#{domain_url}"
      end

      @log = get_logger
      @namespace = get_namespace
      login
      check_privilege(@is_admin)
    end

    def inspect
      "#<BVT::Harness::CFSession '#@TARGET', '#@email'>"
    end

    def login
      @log.debug("Login in, target: #{@TARGET}, email = #{@email}")
      @client = CFoundry::Client.new(@TARGET)
      begin
        @token = @client.login({:username => @email, :password =>  @passwd})
      rescue Exception => e
        @log.error "Fail to login in, target: #{@TARGET}, user: #{@email}"
        raise "Cannot login target environment:\n" +
              "target = '#{@TARGET}', user: '#{@email}'.\n" +
              "Pleae check your ENV and #{VCAP_BVT_CONFIG_FILE}" + "\n#{e.to_s}"
      end
      # TBD - ABS: This is a hack around the 1 sec granularity of our token time stamp
      sleep(1)
      if v2?
        select_org_and_space
      end
    end

    def logout
      @log.debug "logout, target: #{@TARGET}, email = #{@email}"
      @client = nil
    end

    def info
      @log.debug "get target info, target: #{@TARGET}"
      @client.info
    end

    def register(email, password)
      @log.debug("Register user: #{email}")
      BVT::Harness::User.new(@client.register(email, password), self)
    end

    def system_frameworks
      system_frameworks = {}
      @log.debug "get system frameworks, target: #{@TARGET}"
      if v2?
        frameworks = @client.frameworks
        frameworks.each { |f|
          system_frameworks[f.name] = {}
          system_frameworks[f.name][:name] = f.name
          system_frameworks[f.name][:description] = f.description
        }
      else
        @info ||= @client.info
        system_frameworks = @info[:frameworks]
      end
      system_frameworks
    end

    def system_runtimes
      @log.debug "get system runtimes, target: #{@TARGET}"
      runtimes = {}
      if v2?
        system_runtimes = @client.runtimes
        system_runtimes.each{ |r|
          runtimes[r.name] = {}
          runtimes[r.name][:name] = r.name
          runtimes[r.name][:description] = r.description
        }
      else
        @info ||= @client.info
        @info[:frameworks].each do |_, f|
          f[:runtimes].each do |r|
            runtimes[r[:name]] = r
          end
        end
      end
      runtimes
    end

    def system_services
      @log.debug "get system services, target: #{@TARGET}"
      services = {}
      @client.services.each do |service|
        s = {}
        s[:description]   = service.description
        s[:versions]      ||= []
        s[:versions]      << service.version
        s[:provider]      = service.provider
        s[:plans]         = service.service_plans.collect {|p| p.name } if v2?
        services[service.label] ||= {}
        services[service.label][service.provider] = s
      end
      services
    end

    def app(name)
      BVT::Harness::App.new(@client.app("#{@namespace}#{name}"), self)
    end

    def apps
      @client.apps.collect {|app| BVT::Harness::App.new(app, self)}
    end

    def services
      @client.service_instances.collect {|service| BVT::Harness::Service.new(service, self)}
    end

    def service(name, require_namespace=true)
      if require_namespace
        BVT::Harness::Service.new(@client.service_instance("#{@namespace}#{name}"), self)
      else
        BVT::Harness::Service.new(@client.service_instance(name), self)
      end
    end

    def select_org_and_space(org_name = "", space_name = "")
      orgs = @client.organizations
      fail "no organizations." if orgs.empty?
      org = orgs.first
      unless org_name == ""
        find = @client.organization_by_name(org_name)
        org = find if find
      end
      @client.current_organization = org
      @current_organization = org

      spaces = @current_organization.spaces
      if spaces.empty?
        @current_space = self.space("space")
        @current_space.create
      else
        spaces.each{ |s|
          @current_space = s if s.name == space_name
        } unless space_name == ""
        @current_space = spaces.first if @current_space.nil?
      end
      @client.current_space = @current_space
    end

    def organizations
      if v2?
        @client.organizations
      else
        fail "not implemented in v1."
      end
    end

    def spaces
      if v2?
        @client.spaces.collect {|space| BVT::Harness::Space.new(space, self)}
      else
        fail "not implemented in v1."
      end
    end

    def space(name, require_namespace=true)
      if require_namespace
        name = "#{@namespace}#{name}"
      end
      begin
        space = @client.space
        space.name = name
        BVT::Harness::Space.new( space, self)
      rescue Exception => e
        @log.error("Fail to get space: #{name}")
        raise RuntimeError, "Fail to get space: " +
            "\n#{e.to_s}"
      end
    end

    def users
      begin
        @log.debug("Get Users for target: #{@client.target}, login email: #{@email}")
        users = @client.users.collect {|user| BVT::Harness::User.new(user, self)}
      rescue Exception => e
        @log.error("Fail to list users for target: #{@client.target}, login email: #{@email}")
        raise RuntimeError, "Fail to list users for target: " +
            "#{@client.target}, login email: #{@email}\n#{e.to_s}"
      end
    end

    def user(email, options={})
      options = {:require_namespace => true}.merge(options)
      email = "#{@namespace}#{email}" if options[:require_namespace]
      BVT::Harness::User.new(@client.user(email), self)
    end

    # It will delete all services and apps belong to login token via client object
    def cleanup!
      if v2?
        # will force to delete all spaces and app/service_instance in each space.
        spaces.each { |space| space.delete(true) }
      else
        services.each { |service| service.delete }
        apps.each { |app| app.delete }
      end
    end

    private

    def get_logger
      VCAP::Logging.logger(File.basename($0))
    end

    # generate random string as prefix for one test example
    BASE36_ENCODE  = 36
    LARGE_INTEGER  = 2**32
    def get_namespace
      "t#{rand(LARGE_INTEGER).to_s(BASE36_ENCODE)}-"
    end

    def get_login_email(expected_admin = false)
      @config ||= BVT::Harness::RakeHelper.get_config
      if ENV['YETI_PARALLEL_USER']
        @config['user']['email']  = ENV['YETI_PARALLEL_USER']
        @config['user']['passwd'] = ENV['YETI_PARALLEL_USER_PASSWD']
      end

      expected_admin ? @config["admin"]["email"] : @config["user"]["email"]
    end

    def get_login_passwd(expected_admin = false)
      ## since no password save, once Yeti user want to run single case
      ## rake helper will launch prompter for password input
      require "harness/rake_helper"
      @config ||= BVT::Harness::RakeHelper.get_config
      if expected_admin
        @config["admin"]["passwd"] ||= BVT::Harness::RakeHelper.get_admin_user_passwd
      else
        @config["user"]["passwd"] ||= BVT::Harness::RakeHelper.get_user_passwd
      end

      expected_admin ? @config["admin"]["passwd"] : @config["user"]["passwd"]
    end

    def get_target
      @config["target"]
    end

    def check_privilege(expect_admin = false)
      expect_privilege = expect_admin ? "admin user" : "normal user"
      actual_privilege = admin? ? "admin user" : "normal user"

      if actual_privilege == expect_privilege
        @log.info "run bvt as #{expect_privilege}"
      else
        @log.error "user type does not match. Expected User Privilege: #{expect_privilege}" +
                       " Actual User Privilege: #{actual_privilege}"
        raise RuntimeError, "user type does not match.\n" +
            " Expected User Privilege: #{expect_privilege}" +
            " Actual User Privilege: #{actual_privilege}"
      end
    end

    def admin?
      if v2?
        #hard code for ccng
        return false
      else
        user = @client.user(@email)
        user.admin?
      end
    end

    def no_v2
      fail "not implemented for v2." if v2?
    end

    def v2?
      @client.is_a?(CFoundry::V2::Client)
    end
  end

end



