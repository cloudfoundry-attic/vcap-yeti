require "yaml"
require "interact"
require "harness"
require "curb"

module BVT::Harness
  module RakeHelper
    include Interactive, ColorHelpers

    VCAP_BVT_DEFAULT_TARGET = "vcap.me"
    VCAP_BVT_DEFAULT_USER = "test@vcap.me"
    VCAP_BVT_DEFAULT_ADMIN = "admin@vcap.me"

    def generate_config_file
      Dir.mkdir(VCAP_BVT_HOME) unless Dir.exists?(VCAP_BVT_HOME)
      get_config

      get_target
      get_user
      get_user_passwd
      get_admin_user
      get_admin_user_passwd

      save_config
    end

    def check_environment
      check_network_connection

      client = BVT::Harness::CFSession.new
      profile = {}
      profile[:runtimes] = client.system_runtimes
      profile[:services] = client.system_services
      profile[:frameworks] = client.system_frameworks
      profile[:script_hash] = get_script_git_hash
      File.open(VCAP_BVT_PROFILE_FILE, "w") { |f| f.write YAML.dump(profile) }
    end

    HTTP_RESPONSE_OK = 200

    def check_network_connection
      get_config unless @config

      easy = Curl::Easy.new
      easy.url = "http://api.#{@config['target']}/info"
      easy.resolve_mode = :ipv4
      easy.timeout = 10
      begin
        easy.http_get
      rescue Curl::Err::CurlError
        raise RuntimeError,
              red("Cannot connect to target environment, #{easy.url}\n" +
                      "Please check your network connection to target environment.")
      end
      unless easy.response_code == HTTP_RESPONSE_OK
        raise RuntimeError,
              red("URL: #{easy.url} response code does not equal to " +
                      "#{HTTP_RESPONSE_OK}\nPlease check your target environment first.")
      end
    end

    def cleanup!
      check_network_connection
      cleanup_services_apps(@config['user']['email'], @config['user']['passwd'])
      cleanup_test_accounts
    end

    private

    def get_config
      if File.exists?(VCAP_BVT_CONFIG_FILE)
        @config = YAML.load_file(VCAP_BVT_CONFIG_FILE)
        raise "Invalid config file format, #{VCAP_BVT_CONFIG_FILE}" unless @config.is_a?(Hash)
      else
        @config = {}
      end
    end

    def get_target
      if ENV['VCAP_BVT_TARGET']
        @config['target'] = ENV['VCAP_BVT_TARGET']
      elsif @config['target'].nil?
        @config['target'] = ask_and_validate("VCAP Target",
                                             '\A.*',
                                             VCAP_BVT_DEFAULT_TARGET
                                            )
      end
    end

    def get_admin_user
      @config['admin'] = {} if @config['admin'].nil?
      if ENV['VCAP_BVT_ADMIN_USER']
        @config['admin']['email'] = ENV['VCAP_BVT_ADMIN_USER']
      elsif @config['admin']['email'].nil?
        @config['admin']['email'] = ask_and_validate('Admin User Email ' +
                                                       '(If you do not know, just type "enter". ' +
                                                       'Some admin user cases may be failed)',
                                                     '\A.*\@',
                                                     VCAP_BVT_DEFAULT_ADMIN
                                                    )
      end
    end

    def get_admin_user_passwd
      if ENV['VCAP_BVT_ADMIN_USER_PASSWD']
        @config['admin']['passwd'] = ENV['VCAP_BVT_ADMIN_USER_PASSWD']
      elsif @config['admin']['passwd'].nil?
        @config['admin']['passwd'] = ask_and_validate('Admin User Passwd ' +
                                                        '(If you do not know, just type "enter". ' +
                                                        'Some admin user cases may be failed)',
                                                      '.*',
                                                      '*',
                                                      '*'
                                                     )
      end
    end

    def get_user
      @config['user'] = {} if @config['user'].nil?
      if ENV['VCAP_BVT_USER']
        @config['user']['email'] = ENV['VCAP_BVT_USER']
      elsif @config['user']['email'].nil?
        @config['user']['email'] = ask_and_validate('User Email',
                                                    '\A.*\@',
                                                    VCAP_BVT_DEFAULT_USER
                                                   )
      end
    end

    def get_user_passwd
      if ENV['VCAP_BVT_USER_PASSWD']
        @config['user']['passwd'] = ENV['VCAP_BVT_USER_PASSWD']
      elsif @config['user'].nil? || @config['user']['passwd'].nil?
        @config['user']['passwd'] = ask_and_validate('User Passwd', '.*', '*', '*')
      end
    end

    def save_config
      File.open(VCAP_BVT_CONFIG_FILE, "w") { |f| f.write YAML.dump(@config) }
      puts yellow("BVT is starting...")
      puts "target: \t#{yellow(@config['target'])}"
      puts "admin user: \t#{yellow(@config['admin']['email'])}" +
              "\t\tadmin user passwd: \t#{yellow(@config['admin']['passwd'])}"
      puts "normal user: \t#{yellow(@config['user']['email'])}" +
               "\tnormal user passwd: \t#{yellow(@config['user']['passwd'])}"
    end

    def ask_and_validate(question, pattern, default = nil, echo = nil)
      res = ask(question, :default => default, :echo => echo)
      while res !~ /#{pattern}/
        puts "Incorrect input"
        res = ask(question, :default => default, :echo => echo)
      end
      res
    end

    def get_script_git_hash
      `git log --pretty=oneline`.split("\n").first
    end

    def cleanup_services_apps(email, passwd)
      session = BVT::Harness::CFSession.new(false, email, passwd)
      puts yellow("Ready to clean up for test user: #{session.email}")
      apps = session.apps
      services = session.services

      if services.empty?
        puts "No service has been provisioned by test user: #{session.email}"
      else
        puts "List all services belong to test user: #{session.email}"
        services.each { |service| puts service.name }
        if ask("Do you want to remove all above servcies?", :default => true)
          services.each { |service| service.delete }
          puts yellow("all services belong to #{session.email} have been removed")
        else
          puts yellow("Keep those services\n")
        end
      end

      if apps.empty?
        puts "No application has been created by test user: #{session.email}"
      else
        puts "List all applications belong to test user: #{session.email}"
        apps.each { |app| puts app.name }
        if ask("Do you want to remove all above applications?", :default => true)
          apps.each { |app| app.delete }
          puts yellow("all applications belong to #{session.email} have been removed")
        else
          puts yellow("Keep those applications\n")
        end
      end

      puts yellow("Clean up work for test user: #{session.email} has been done.\n")
    end

    def cleanup_test_accounts()
      test_user_template = 'my_fake@email.address'
      session = BVT::Harness::CFSession.new(true)
      puts yellow("Ready to remove all test users created in admin_user_spec.rb")
      users = session.users.select { |user| user.email =~ /^t.*-#{test_user_template}$/ }

      if users.empty?
        puts "No test user need to be deleted."
      else
        puts "List all test users"
        users.each { |user| puts user.email }
        if ask("Do you want to remove all above users?", :default => true)
          users.each { |user| user.delete }
        else
          puts yellow("Keep those test users\n")
        end
      end
      puts yellow("Clean up test accounts has been done.\n")
    end

    extend self
  end
end
