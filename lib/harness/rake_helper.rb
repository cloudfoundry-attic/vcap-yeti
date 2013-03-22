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

    VCAP_BVT_DEFAULT_TARGET =   "api.vcap.me"
    VCAP_BVT_DEFAULT_USER   =   "test@vcap.me"
    VCAP_BVT_DEFAULT_ADMIN  =   "admin@vcap.me"

    def prepare_all(threads=nil)
      Dir.mkdir(VCAP_BVT_HOME) unless Dir.exists?(VCAP_BVT_HOME)
      @print_config = []
      get_target
      check_network_connection

      if threads == nil
        get_admin_user
        get_admin_user_passwd
      elsif threads < 1 || threads > VCAP_BVT_PARALLEL_MAX_USERS
        puts red("threads number must be within 1~#{VCAP_BVT_PARALLEL_MAX_USERS}")
        exit(1)
      else
        parallel_users = get_parallel_users(true)
        if threads > 1
          if parallel_users.size == 0
            parallel_users = create_parallel_users(VCAP_BVT_PARALLEL_MAX_USERS)
          elsif parallel_users.size < threads
            puts yellow("no enough parallel users, yeti will use all of the #{parallel_users.size} users")
          end
        end
        check_env_user = get_check_env_user(parallel_users)
        check_environment(check_env_user)
      end

      save_config
      print_test_config
    end

    def check_environment(user)
      client = BVT::Harness::CFSession.new(:email => user['email'],
                                           :passwd => user['passwd'],
                                           :target => @config['target'])
      profile = {}
      profile[:services] = client.system_services
      profile[:script_hash] = get_script_git_hash
      target_without_http = @config['target'].split('//')[-1]
      $vcap_bvt_profile_file ||= File.join(BVT::Harness::VCAP_BVT_HOME,
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

    def check_user_availability(user)
      begin
        client = BVT::Harness::CFSession.new(:email => user['email'],
                                             :passwd => user['passwd'],
                                             :target => @config['target'])
      rescue => e
        puts e.message
        return false
      end
      return true
    end

    def cleanup!
      get_target
      get_user
      get_user_passwd
      save_config
      check_network_connection
      cleanup_user_data(@config['user']['email'], @config['user']['passwd'])
      if @config['parallel']
        @config['parallel'].each do |puser|
          cleanup_user_data(puser['email'], puser['passwd'])
        end
      end
      # clear parallel env
      ENV.delete('YETI_PARALLEL_USER')
      ENV.delete('YETI_PARALLEL_USER_PASSWD')
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
        raise "Invalid config file format, #{VCAP_BVT_CONFIG_FILE}" unless @multi_target_config.is_a?(Hash)
      else
        @multi_target_config = {} unless @multi_target_config
      end
      @config = {} unless @config

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

    def save_config(hash = nil)
      @config = hash || @config

      ## remove password
      @config['user'].delete('passwd') if @config['user']
      @config['admin'].delete('passwd') if @config['admin']

      ## remove http(s) from target
      @config['target'] = @config['target'].split('//')[-1]

      @multi_target_config[@config['target']] = @config

      File.open(VCAP_BVT_CONFIG_FILE, "w") { |f| f.write YAML.dump(@multi_target_config) }
    end

    def get_target
      if ENV['VCAP_BVT_TARGET']
        target = format_target(ENV['VCAP_BVT_TARGET'])
        @print_config << "target read from ENV: \t\t#{yellow(target)}" if @print_config
      else
        input = ask_and_validate("VCAP Target",
                                 '\A.*',
                                 VCAP_BVT_DEFAULT_TARGET)
        target = format_target(input)
      end
      @multi_target_config = {} unless @multi_target_config
      @multi_target_config[target] = {} unless @multi_target_config.key?(target)
      @config = @multi_target_config[target]
      ENV['VCAP_BVT_TARGET'] = target
      get_config
      @config['target'] = target
      @config['target']
    end

    def get_admin_user
      get_config unless @config
      @config['admin'] = {} if @config['admin'].nil?
      if ENV['VCAP_BVT_ADMIN_USER']
        @config['admin']['email'] = ENV['VCAP_BVT_ADMIN_USER']
        @print_config << "admin user read from ENV: \t#{yellow(@config['admin']['email'])}" if @print_config
      elsif @config['admin']['email'].nil?
        @config['admin']['email'] = ask_and_validate('Admin User',
                                                     '\A.*\@',
                                                     VCAP_BVT_DEFAULT_ADMIN
                                                    )
      else
        @print_config << "admin user read from #{VCAP_BVT_CONFIG_FILE}: " +
             "\t#{yellow(@config['admin']['email'])}" if @print_config
      end
      @config['admin']['email']
    end

    def get_admin_user_passwd
      get_config unless @config
      if ENV['VCAP_BVT_ADMIN_USER_PASSWD']
        @config['admin']['passwd'] = ENV['VCAP_BVT_ADMIN_USER_PASSWD']
      elsif @config['admin']['passwd'].nil?
        @config['admin']['passwd'] = ask_and_validate("Admin User Passwd " +
                                                          "(#{yellow(@config['admin']['email'])})",
                                                      '.*',
                                                      '*',
                                                      '*'
                                                     )
      end
      ENV['VCAP_BVT_ADMIN_USER_PASSWD'] = @config['admin']['passwd'].to_s
      @config['admin']['passwd'] = @config['admin']['passwd'].to_s
      @config['admin']['passwd']
    end

    def get_user
      get_config unless @config
      @config['user'] = {} if @config['user'].nil?
      if ENV['VCAP_BVT_USER']
        @config['user']['email'] = ENV['VCAP_BVT_USER']
        @print_config << "normal user read from ENV: \t#{yellow(@config['user']['email'])}" if @print_config
      elsif @config['user']['email'].nil?
        @config['user']['email'] = ask_and_validate('Non-admin User',
                                                    '\A.*\@',
                                                    VCAP_BVT_DEFAULT_USER
                                                   )
      else
        @print_config << "normal user read from #{VCAP_BVT_CONFIG_FILE}: " +
             "\t#{yellow(@config['user']['email'])}" if @print_config
      end
      @config['user']['email']
    end

    def get_user_passwd
      get_config unless @config
      if ENV['VCAP_BVT_USER_PASSWD']
        @config['user']['passwd'] = ENV['VCAP_BVT_USER_PASSWD']
      elsif @config['user'].nil? || @config['user']['passwd'].nil?
        @config['user']['passwd'] = ask_and_validate("User Passwd " +
                                                         "(#{yellow(@config['user']['email'])})",
                                                     '.*',
                                                     '*',
                                                     '*')
      end
      ENV['VCAP_BVT_USER_PASSWD'] = @config['user']['passwd'].to_s
      @config['user']['passwd']   = @config['user']['passwd'].to_s
      @config['user']['passwd']
    end

    def create_parallel_users(user_number)
      puts "need admin account to create parallel users"
      get_admin_user
      get_admin_user_passwd

      @config['parallel'] = []
      session = nil
      begin
        session = BVT::Harness::CFSession.new(:admin => true,
                                              :email => @config['admin']['email'],
                                              :passwd => @config['admin']['passwd'],
                                              :target => @config['target'])
      rescue Exception => e
        raise RuntimeError, "#{e.to_s}\nPlease input valid admin credential " +
                            "for parallel running"
      end

      passwd = 'aZ_x13YcIa4nhl'  #parallel user secret
      (1..user_number).to_a.each do |index|
        config = {}
        if session.v2?
          @uaa_cc_secret ||= get_uaa_cc_secret
          uaa_url = @config['target'].gsub(/\/\/\w+/, '//uaa')
          email = session.namespace + "#{index}-test_user@vmware.com"
          org_name = session.namespace + "yeti_test_org-#{index}"
          space_name = "yeti_test_space"
          CCNGUserHelper.create_user(uaa_url, @uaa_cc_secret, @config['target'], @config['admin']['email'],
                                     @config['admin']['passwd'], email, passwd, org_name, space_name)
          config['email']  = email
        else
          email = "#{index}-test_user@vmware.com"
          user  = session.user(email)
          user.create(passwd)
          config['email']  = user.email
        end
        config['passwd'] = passwd
        puts "create user: #{yellow(config['email'])}"
        $stdout.flush
        @config['parallel'] << config
      end
      @config['admin'].delete('passwd')
      @config['parallel']
    end

    def get_parallel_users(check_user=false)
      parallel_users = []
      parallel_users = @config['parallel'] if @config && @config['parallel']
      if parallel_users.size > 0
        parallel_users.each do |puser|
          puser['passwd'] = puser['passwd'].to_s
        end
        if check_user
          if check_user_availability(parallel_users[0]) == false
            puts red("can't login target env using parallel user: #{parallel_users[0]}")
            exit(1)
          end
        end
      end
      parallel_users
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
      @uaa_cc_secret = nil
      if ENV['VCAP_BVT_UAA_CC_SECRET']
        @uaa_cc_secret = ENV['VCAP_BVT_UAA_CC_SECRET']
      elsif ENV['VCAP_BVT_DEPLOY_MANIFEST']
        begin
          deploy_manifest = YAML.load_file(ENV['VCAP_BVT_DEPLOY_MANIFEST'])
          @uaa_cc_secret = deploy_manifest['properties']['uaa']['cc']['client_secret']
        rescue
          puts red("can't find uaa_cc_secret in your manifest")
          exit(-1)
        end
      else
        @uaa_cc_secret = ask_and_validate("uaa_cc_client_secret", '\S*')
      end
      @uaa_cc_secret
    end

    private

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

    def cleanup_user_data(email, passwd)
      session = BVT::Harness::CFSession.new(:email => email,
                                            :passwd => passwd,
                                            :target => @config['target'])
      puts yellow("Ready to clean up for test user: #{session.email}")

      services = session.client.service_instances
      puts yellow("Begin to clean up services")
      cleanup_data(session, services)

      apps = session.client.apps
      puts yellow("Begin to clean up apps")
      cleanup_data(session, apps)

      if session.v2?
        routes = session.client.routes
        puts yellow("Begin to clean up routes")
        cleanup_data(session, routes)

        domains = session.client.domains
        puts yellow("Begin to clean up domains")
        cleanup_data(session, domains)
      end

      puts yellow("Clean up work for test user: #{session.email} has been done.\n")
    end

    def is_parallel_user?(email)
      return true if email =~ /^t\w{6,7}-\d{1,2}-/ #parallel user, delete without asking
      false
    end

    def cleanup_data(session, objs)
      if objs.empty?
        puts "No instance has been created by test user: #{session.email}"
      elsif is_parallel_user?(session.email)
        objs.each{ |obj|
          puts "deleting #{obj.class.to_s}: #{obj.name}..."
          obj.delete!
        }
      else
        puts "List all instances belong to test user: #{session.email}"
        # filter system domain, since system domain cannot be removed via normal user
        if objs.first.class.to_s =~ /Domain/
          system_domain = session.TARGET.split(".", 2).last
          objs.reject! {|obj| obj.name =~ /#{system_domain}/}
        end

        objs.each { |obj| puts obj.name }
        if  ask("Do you want to remove all above instances?", :default => true)
          objs.each { |obj| obj.delete! }
          puts yellow("all instances belong to #{session.email} have been removed")
        else
          puts yellow("keep above ones\n")
        end
      end
    end

    def cleanup_test_accounts
      test_user_template = 'my_fake@email.address'

      session = BVT::Harness::CFSession.new(:admin => true,
                                            :email => @config['admin']['email'],
                                            :passwd => @config['admin']['passwd'],
                                            :target => @config['target'])
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

    def get_assets_info
      url = "#{VCAP_BVT_ASSETS_STORE_URL}/list"
      begin
        r = RestClient.get url
      rescue
        raise RuntimeError,
              red("Cannot connect to yeti assets storage server, #{url}\n" +
                      "Please check your network connection.")
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
              red("Download faild, might be caused by unstable network.\n" +
                      "Please try again.")
      end

      if r && r.code == HTTP_RESPONSE_CODE::OK
        contents = r.to_str.chomp
        File.open(filepath, 'wb') { |f| f.write(contents) }
      else
        raise RuntimeError, "Fail to download binary #{filename}"
      end
    end

    extend self
  end
end
