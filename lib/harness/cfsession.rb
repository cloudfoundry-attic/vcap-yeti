require "cfoundry"
require "vcap/logging"
require "harness/rake_helper"

module BVT::Harness
  class CFSession
    attr_reader :log, :namespace, :TARGET, :email, :passwd, :token, :current_organization, :current_space,
                :client

    def initialize(options = {})
      options = {:admin => false,
                 :email => nil,
                 :passwd => nil,
                 :target => nil}.merge(options)

      if options[:target]
        @TARGET = RakeHelper.format_target(options[:target])
      else
        @TARGET = RakeHelper.get_target
      end

      @email = options[:email] ? options[:email] : get_login_email(options[:admin])
      @passwd = options[:passwd] ? options[:passwd] : get_login_passwd(options[:admin])

      # Restrict admin from performing non-admin operations
      unless options[:admin]
        if is_user_admin?(@email, @passwd)
          raise RuntimeError, "current operation can not be performed as" +
            " user with admin privileges"
        end
      end

      LoggerHelper::set_logger(@TARGET)

      @log = get_logger
      @namespace = get_namespace
      login
      check_privilege(options[:admin]) unless v2?
    end

    def inspect
      "#<BVT::Harness::CFSession '#@TARGET', '#@email'>"
    end

    def login
      @log.debug("Login in, target: #{@TARGET}, email = #{@email}")
      @client = CFoundry::Client.new(@TARGET)
      @client.trace = true if ENV['VCAP_BVT_TRACE']
      @client.log = []
      begin
        @token = @client.login(@email, @passwd)
      rescue Exception => e
        @log.error "Fail to login in, target: #{@TARGET}, user: #{@email}\n#{e.to_s}"
        raise "Cannot login target environment:\n" +
              "target = '#{@TARGET}', user: '#{@email}'.\n" +
              "Pleae check your ENV and #{VCAP_BVT_CONFIG_FILE}" + "\n#{e.to_s}\n#{print_client_logs}"
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
      User.new(@client.register(email, password), self)
    end

    def system_services
      @log.debug "get system services, target: #{@TARGET}"
      services = {}

      @client.services.each do |service|
        s = {}
        s[:description]   = service.description
        versions = []
        if services[service.label]
          versions = services[service.label][service.provider][:versions] if services[service.label][service.provider]
        end
        versions          << service.version.to_s unless versions.index(service.version.to_s)
        s[:provider]      = service.provider
        s[:plans]         = service.service_plans.collect {|p| p.name } if v2?
        services[service.label] ||= {}
        services[service.label][service.provider] = s
        services[service.label][service.provider][:versions] = versions
      end
      services
    end

    def app(name, prefix = '', domain=nil)
      app = @client.app
      app.name = "#{prefix}#{@namespace}#{name}"
      App.new(app, self, domain)
    end

    def apps
      @client.apps.collect {|app| App.new(app, self)}
    end

    def services
      @client.service_instances.collect {|service| Service.new(service, self)}
    end

    def service(name, require_namespace=true)
      instance = @client.service_instance
      instance.name = require_namespace ? "#{@namespace}#{name}" : name
      BVT::Harness::Service.new(instance, self)
    end

    def select_org_and_space(org_name = "", space_name = "")
      orgs = @client.organizations
      fail "no organizations." if orgs.empty?
      org = orgs.first
      unless org_name == ""
        find = @client.organization_by_name(org_name)
        org = find if find
      end
      @current_organization = org

      spaces = @current_organization.spaces
      if spaces.empty?
        space = @client.space
        space.name = "#{@namespace}space"
        space.organization = @current_organization
        space.create!
        space.add_developer @client.current_user
        @current_space = space
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
        raise RuntimeError, "not support in CCNG v1 API"
      end
    end

    def spaces
      if v2?
        @client.spaces.collect {|space| BVT::Harness::Space.new(space, self)}
      else
        raise RuntimeError, "not support in CCNG v1 API"
      end
    end

    def domains
      if v2?
        @client.domains.collect {|domain| BVT::Harness::Domain.new(domain, self)}
      else
        raise RuntimeError, "not support in CCNG v1 API"
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
            "\n#{e.to_s}\n#{print_client_logs}"
      end
    end

    def domain(name, require_namespace=true)
      if require_namespace
        name = "#{@namespace}#{name}"
      end
      begin
        domain = @client.domain
        domain.wildcard = true
        domain.name = name
        BVT::Harness::Domain.new( domain, self)
      rescue Exception => e
        @log.error("Fail to create domain: #{name}")
        raise RuntimeError, "Fail to create domain: " +
            "\n#{e.to_s}\n#{print_client_logs}"
      end
    end

    def users
      begin
        @log.debug("Get Users for target: #{@client.target}, login email: #{@email}")
        users = @client.users.collect {|user| User.new(user, self)}
      rescue Exception => e
        @log.error("Fail to list users for target: #{@client.target}, login email: #{@email}")
        raise RuntimeError, "Fail to list users for target: " +
            "#{@client.target}, login email: #{@email}\n#{e.to_s}"
      end
    end

    def user(email, options={})
      options = {:require_namespace => true}.merge(options)
      email = "#{@namespace}#{email}" if options[:require_namespace]
      User.new(@client.user(email), self)
    end

    def get_target_domain
      @TARGET.split(".", 2).last
    end

    # It will delete all services and apps belong to login token via client object
    # mode: current -> delete app/service_instance in current space.
    # mode: all -> delete app/service_instance in each space
    def cleanup!(mode = "current")
      if v2?
        target_domain = get_target_domain
        if (mode == "all")
          @client.spaces.each{ |s|
            s.apps.each {|app| app.delete!}
            s.service_instances.each {|service| service.delete!}
          }
          @client.routes.each { |route| route.delete! }
        elsif (mode == "current")
          # CCNG cannot delete service which binded to application
          # therefore, remove application first
          @client.current_organization = @current_organization
          @client.current_space = @current_space
          apps.each {|app| app.delete}
          services.each {|service| service.delete}
          @client.routes.each { |route| route.delete! }
        end
      else
        apps.each { |app| app.delete }
        services.each { |service| service.delete }
      end
    end

    def v1?
      @client.is_a?(CFoundry::V1::Client)
    end

    def v2?
      @client.is_a?(CFoundry::V2::Client)
    end

    def print_client_logs
      lines = ""
      unless @client.log.empty?
        @client.log.reverse.each do |item|
          lines += "\n#{parse_log_line(item)}"
        end
      end

      @client.log = []
      lines
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
      if expected_admin
        RakeHelper.get_admin_user
      else
        ENV['YETI_PARALLEL_USER'] || RakeHelper.get_user
      end
    end

    def get_login_passwd(expected_admin = false)
      if expected_admin
        RakeHelper.get_admin_user_passwd
      else
        ENV['YETI_PARALLEL_USER_PASSWD'] || RakeHelper.get_user_passwd
      end
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
      begin
        is_user_admin?(@email, @passwd)
      rescue Exception => e
        @log.error("Fail to check user's admin privilege. Target: #{@client.target},"+
                       " login email: #{@email}\n#{e.to_s}")
        raise RuntimeError, "Fail to check user's admin privilege. Target: #{@client.target},"+
            " login email: #{@email}\n#{e.to_s}\n#{print_client_logs}"
      end
    end

    def no_v2
      fail "not implemented for v2." if v2?
    end

    def parse_log_line(item)
      date        = item[:response][:headers]["date"]
      time        = "%.6f" % item[:time].to_f
      rest_method = item[:request][:method].upcase
      code        = item[:response][:code]
      url         = item[:request][:url]

      if item[:response][:headers]["x-vcap-request-id"]
        request_id  = item[:response][:headers]["x-vcap-request-id"]
      else
        request_id  = ""
      end

      "[#{date}]  #{time}\t#{request_id}  #{rest_method}\t-> #{code}\t#{url}"
    end
  end

  private

  def is_user_admin?(email, passwd)
    if v1? && @client
      @client.user(email).admin?
    else
      # Currently cfoundry v2 can only check
      # if user is an admin if we logged in as admin
      check_admin_client = CFoundry::Client.new(@TARGET)
      check_admin_client.login(email, passwd)
      begin
        check_admin_client.current_user.admin?
      rescue CFoundry::APIError
        false
      end
    end
  end
end