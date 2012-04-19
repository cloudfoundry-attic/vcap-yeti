require "yaml"
require "interact"
require "harness"
require "curb"
require "harness/color_helper"

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
      puts "Environment profile written to #{VCAP_BVT_PROFILE_FILE}"
    end

    private

    def get_config
      if File.exists?(VCAP_BVT_CONFIG_FILE)
        puts "Using config file #{VCAP_BVT_CONFIG_FILE}"
        @config = YAML.load_file(VCAP_BVT_CONFIG_FILE)
        raise "Invalid config file format, #{VCAP_BVT_CONFIG_FILE}" unless @config.is_a?(Hash)
      else
        puts "Can't find config file at #{VCAP_BVT_CONFIG_FILE}"
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
      puts "Config file written to #{VCAP_BVT_CONFIG_FILE}"
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

    def check_network_connection
      easy = Curl::Easy.new
      easy.url = "http://api.#{@config['target']}/info"
      easy.resolve_mode = :ipv4
      easy.timeout = 10
      begin
        easy.http_get
      rescue Curl::Err::TimeoutError
        raise RuntimeError, red("Cannot connect to target environment, #{easy.url}\n" +
            "Please check your network connection to target environment.")
      end
      raise RuntimeError, red("URL: #{easy.url} response code does not equal to 200.\n" +
                                  "Please check your target environment first.") unless easy.response_code == 200
    end

    extend self
  end
end
