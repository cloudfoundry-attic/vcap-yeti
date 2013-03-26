require "yaml"
require "interact"
require "harness"
require "mongo"
require "yajl"
require "digest/md5"
require "tempfile"

module BVT::Harness
  module RakeHelper
    include Interactive, ColorHelpers

    VCAP_BVT_DEFAULT_TARGET = "api.vcap.me"
    VCAP_BVT_DEFAULT_USER   = "test@vcap.me"
    VCAP_BVT_DEFAULT_ADMIN  = "admin@vcap.me"

    def prepare_all(threads)
      if threads < 1 || threads > VCAP_BVT_PARALLEL_MAX_USERS
        abort("Threads number must be within 1..#{VCAP_BVT_PARALLEL_MAX_USERS}")
      end

      Dir.mkdir(VCAP_BVT_HOME) unless Dir.exists?(VCAP_BVT_HOME)
      @print_config = []

      get_target
      check_network_connection

      parallel_users = get_parallel_users(true)
      if threads > 1
        if parallel_users.size == 0
          parallel_users = create_parallel_users(VCAP_BVT_PARALLEL_MAX_USERS)
        elsif parallel_users.size < threads
          puts yellow("Not enough parallel users, yeti will use all of the #{parallel_users.size} users")
        end
      end

      user = get_check_env_user(parallel_users)
      generate_profile(user)

      save_config
      print_test_config
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

    def check_network_connection
      url = "#{@config['target']}/info"

      begin
        r = RestClient.get url
      rescue
        raise RuntimeError,
          red("Cannot connect to target environment, #{url}\n" +
              "Please check your network connection to target environment.")
      end

      unless r.code == HTTP_RESPONSE_CODE::OK
        raise RuntimeError,
          red("URL: #{url} response code is: " +
              "#{r.code}\nPlease check your target environment first.")
      end
    end

    def sync_assets
      downloads = get_assets_info
      if downloads == nil
        raise RuntimeError,
          red("Get remote file list faild, might be caused by unstable network.\n" +
              "Please try again.")
      end
      if File.exist?(VCAP_BVT_ASSETS_PACKAGES_MANIFEST)
        locals = YAML.load_file(VCAP_BVT_ASSETS_PACKAGES_MANIFEST)['packages']
      else
        locals = []
      end
      puts "check local assets binaries"
      skipped = []
      unless locals.empty?
        total = locals.length
        locals.each_with_index do |item, index|
          downloads_index = downloads.index {|e| e['filename'] == item['filename']}
          index_str = "[#{(index + 1).to_s}/#{total.to_s}]"
          if downloads_index
            if downloads[downloads_index]['md5'] == item['md5']
              puts green("#{index_str}Skipped\t\t#{item['filename']}")
              downloads.delete_at(downloads_index)
              skipped << Hash['filename' => item['filename'], 'md5' => item['md5']]
            else
              puts yellow("#{index_str}Need to update\t#{item['filename']}")
            end
          else
            puts red("#{index_str}Remove\t\t#{item['filename']}")
            File.delete(File.join(VCAP_BVT_ASSETS_PACKAGES_HOME, item['filename']))
          end
        end
      end

      unless downloads.empty?
        puts "\ndownloading assets binaries"
        Dir.mkdir(VCAP_BVT_ASSETS_PACKAGES_HOME) unless Dir.exist?(VCAP_BVT_ASSETS_PACKAGES_HOME)
        total = downloads.length
        downloads.each_with_index do |item, index|
          index_str = "[#{(index + 1).to_s}/#{total.to_s}]"
          filepath = File.join(VCAP_BVT_ASSETS_PACKAGES_HOME, item['filename'])
          puts yellow("#{index_str}downloading\t#{item['filename']}")
          download_binary(filepath)
          actual_md5 = check_md5(filepath)
          unless actual_md5 == item['md5']
            puts red("#{index_str}fail to download\t\t#{item['filename']}.\n"+
                     "Might be caused by unstable network, please try again.")
          end
          skipped << Hash['filename' => item['filename'], 'md5' => actual_md5]
          File.open(VCAP_BVT_ASSETS_PACKAGES_MANIFEST, "w") do |f|
            f.write YAML.dump(Hash['packages' => skipped])
          end
        end
      end
      puts green("sync assets binaries finished")
    end

    def print_test_config
      @print_config.each do |line|
        puts line
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
      @config['user']['email'] = require_env!("VCAP_BVT_USER")
    end

    def get_user_passwd
      get_config unless @config
      @config['user'] ||= {}
      @config['user']['passwd'] = require_env!("VCAP_BVT_USER_PASSWD")
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
      {'email' => @config['user']['email'], 'passwd' => @config['user']['passwd']}
    end

    def format_target(str)
      if str.start_with? 'http'
        str
      else
        'https://' + str
      end
    end

    def get_uaa_cc_secret
      require_env!("VCAP_BVT_UAA_CC_SECRET")
    end

    private

    def get_script_git_hash
      `git log -1 --pretty=oneline`.split("\n").first
    end

    def get_assets_info
      url = "#{VCAP_BVT_ASSETS_STORE_URL}/list"
      begin
        r = RestClient.get url
      rescue
        raise RuntimeError,
          "Cannot connect to yeti assets storage server, #{url}\n" +
          "Please check your network connection."
      end

      if r.code == HTTP_RESPONSE_CODE::OK
        parser = Yajl::Parser.new
        return parser.parse(r.to_str)
      end
    end

    def check_md5(filepath)
      Digest::MD5.hexdigest(File.read(filepath))
    end

    def download_binary(filepath)
      filename = File.basename(filepath)
      url = "#{VCAP_BVT_ASSETS_STORE_URL}/files/#{filename}"
      r = nil
      begin
        # retry 5 times if download failed
        5.times do
          begin
            r = RestClient.get url
          rescue
            next
          end
          break if r.code == HTTP_RESPONSE_CODE::OK
          sleep(1)
        end
      rescue
        raise RuntimeError,
          "Download failed, might be caused by unstable network."
      end

      if r && r.code == HTTP_RESPONSE_CODE::OK
        contents = r.to_str.chomp
        File.open(filepath, 'wb') { |f| f.write(contents) }
      else
        raise RuntimeError, "Fail to download binary #{filename}"
      end
    end

    private

    def running_in_parallel?
      ENV["TEST_ENV_NUMBER"]
    end

    def parallel_run_number
      raise ArgumentError, "Not running in parallel" \
        unless running_in_parallel?
      ENV["TEST_ENV_NUMBER"].to_i
    end

    def require_env!(var_name)
      if value = ENV[var_name]
        value
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
