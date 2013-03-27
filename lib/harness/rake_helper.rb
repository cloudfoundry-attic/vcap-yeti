require "yaml"
require "harness"
require "tempfile"

module BVT::Harness
  module RakeHelper
    def prepare_all(threads)
      if threads < 1 || threads > VCAP_BVT_PARALLEL_MAX_USERS
        abort("Threads number must be within 1..#{VCAP_BVT_PARALLEL_MAX_USERS}")
      end

      Dir.mkdir(VCAP_BVT_HOME) unless Dir.exists?(VCAP_BVT_HOME)

      get_target
      check_target

      parallel_users = get_parallel_users(true)
      if threads > 1
        if parallel_users.size == 0
          parallel_users = create_parallel_users(VCAP_BVT_PARALLEL_MAX_USERS)
        elsif parallel_users.size < threads
          puts "Not enough parallel users, yeti will use all of the #{parallel_users.size} users"
        end
      end

      user = get_check_env_user(parallel_users)
      generate_profile(user)
      save_config
    end

    def generate_profile(user)
      client = BVT::Harness::CFSession.new(
        :email => user['email'],
        :passwd => user['passwd'],
        :target => @config['target']
      )

      profile = {}
      profile[:services] = client.system_services
      profile[:script_hash] = get_script_git_hash

      target_without_http = @config['target'].split('//')[-1]
      $vcap_bvt_profile_file ||=
        File.join(BVT::Harness::VCAP_BVT_HOME,
                  "profile.#{target_without_http}.yml")
      File.open($vcap_bvt_profile_file, "w") { |f| f.write YAML.dump(profile) }
    end

    def check_target
      url = "#{@config['target']}/info"

      begin
        r = RestClient.get(url)
      rescue
        raise RuntimeError,
          "Cannot connect to target environment, #{url}\n" +
          "Please check your network connection to target environment."
      end

      unless r.code == HTTP_RESPONSE_CODE::OK
        raise RuntimeError,
          "URL: #{url} response code is: " +
          "#{r.code}\nPlease check your target environment first."
      end
    end

    def get_config
      if File.exists?(VCAP_BVT_CONFIG_FILE)
        @multi_target_config = YAML.load_file(VCAP_BVT_CONFIG_FILE)
        raise "Invalid config file format, #{VCAP_BVT_CONFIG_FILE}" \
          unless @multi_target_config.is_a?(Hash)
      else
        @multi_target_config ||= {}
      end

      @config ||= {}

      # since multi-target information is stored in one config file,
      # so usually get_config method just initiate @config, and @multi_target_config
      # however, once user set environment variable VCAP_BVT_TARGET,
      # get_config method should return specific target information
      if ENV['VCAP_BVT_TARGET']
        target = format_target(ENV['VCAP_BVT_TARGET'])
        @multi_target_config.keys.each do |key|
          if target.include? key
            @config = @multi_target_config[key]
            break
          end
        end
      end

      @config
    end

    def save_config
      ## remove password
      @config['user'].delete('passwd') if @config['user']
      @config['admin'].delete('passwd') if @config['admin']

      ## remove http(s) from target
      @config['target'] = @config['target'].split('//')[-1]

      @multi_target_config[@config['target']] = @config

      File.open(VCAP_BVT_CONFIG_FILE, "w") do |f|
        f.write YAML.dump(@multi_target_config)
      end

      puts "Wrote config to #{VCAP_BVT_CONFIG_FILE}"
    end

    def get_target
      target = require_env!("VCAP_BVT_TARGET")
      target = format_target(target)

      @multi_target_config ||= {}
      @multi_target_config[target] ||= {}

      @config = @multi_target_config[target]
      ENV['VCAP_BVT_TARGET'] = target

      get_config
      @config['target'] = target
    end

    def get_admin_user
      get_config unless @config
      @config['admin'] ||= {}
      @config['admin']['email'] = require_env!("VCAP_BVT_ADMIN_USER")
    end

    def get_admin_user_passwd
      get_config unless @config
      @config['admin'] ||= {}
      @config['admin']['passwd'] = require_env!("VCAP_BVT_ADMIN_USER_PASSWD")
    end

    def get_user
      get_config unless @config
      @config['user'] ||= {}
      @config['user']['email'] = \
        require_env!("VCAP_BVT_USER", first_parallel_user)
    end

    def get_user_passwd
      get_config unless @config
      @config['user'] ||= {}
      @config['user']['passwd'] = \
        require_env!("VCAP_BVT_USER_PASSWD", first_parallel_user_passwd)
    end

    def create_parallel_users(user_number)
      puts "Using admin account to create parallel users:"
      get_admin_user
      get_admin_user_passwd

      @config['parallel'] = []
      session = BVT::Harness::CFSession.new(
        :admin => true,
        :email => @config['admin']['email'],
        :passwd => @config['admin']['passwd'],
        :target => @config['target']
      )

      passwd = 'aZ_x13YcIa4nhl'  #parallel user secret

      (1..user_number).to_a.each do |index|
        config = {}

        if session.v2?
          uaa_url = @config['target'].gsub(/\/\/\w+/, '//uaa')
          email = "#{session.namespace}#{index}-test_user@vmware.com"
          org_name = "#{session.namespace}yeti_test_org-#{index}"
          space_name = "yeti_test_space"

          CCNGUserHelper.create_user(
            uaa_url, get_uaa_cc_secret,
            @config['target'],
            @config['admin']['email'],
            @config['admin']['passwd'],
            email, passwd,
            org_name, space_name
          )
          config['email'] = email
        else
          email = "#{index}-test_user@vmware.com"
          user  = session.user(email)
          user.create(passwd)
          config['email']  = user.email
        end

        config['passwd'] = passwd
        puts " - #{config['email']}"
        $stdout.flush

        @config['parallel'] << config
      end

      @config['admin'].delete('passwd')
      @config['parallel']
    end

    def get_parallel_users(check_first_user=false)
      @config ||= {}
      return [] unless parallel_users = @config['parallel']

      if check_first_user
        first_user = parallel_users[0]
        unless check_user_availability(first_user)
          abort("Cannot login using first parallel user: #{first_user}")
        end
      end

      parallel_users
    end

    def set_up_parallel_user
      if running_in_parallel?
        login = get_parallel_users[parallel_run_number]
        ENV["YETI_PARALLEL_USER"] = login["email"]
        ENV["YETI_PARALLEL_USER_PASSWD"] = login["passwd"]
      end
    end

    def get_check_env_user(parallel_users)
      if parallel_users.size > 0
        return parallel_users[0]
      else
        get_user
        get_user_passwd
      end
      { 'email' => @config['user']['email'],
        'passwd' => @config['user']['passwd'] }
    end

    def format_target(str)
      if str.start_with? 'http'
        str
      else
        'https://' + str
      end
    end

    private

    def first_parallel_user
      return unless users = get_parallel_users
      return unless user = users[0]
      user['email']
    end

    def first_parallel_user_passwd
      return unless users = get_parallel_users
      return unless user = users[0]
      user['passwd']
    end

    def get_uaa_cc_secret
      require_env!("VCAP_BVT_UAA_CC_SECRET")
    end

    def get_script_git_hash
      `git log -1 --pretty=oneline`.split("\n").first
    end

    def running_in_parallel?
      ENV["TEST_ENV_NUMBER"]
    end

    def parallel_run_number
      raise ArgumentError, "Not running in parallel" \
        unless running_in_parallel?
      ENV["TEST_ENV_NUMBER"].to_i
    end

    def require_env!(var_name, default_value=nil)
      if value = ENV[var_name]
        value
      elsif default_value
        default_value
      else
        abort("Please specify #{var_name}")
      end
    end

    def check_user_availability(user)
      BVT::Harness::CFSession.new(
        :email => user['email'],
        :passwd => user['passwd'],
        :target => @config['target']
      )
      true
    rescue => e
      puts e.message
      false
    end

    extend self
  end
end
