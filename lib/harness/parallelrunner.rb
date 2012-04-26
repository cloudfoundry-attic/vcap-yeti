require "harness"
require "find"

module BVT::Harness
  module ParallelRunner
    include ColorHelpers

    def create_parallel_users
      user_info = YAML.load_file(VCAP_BVT_CONFIG_FILE)
      unless user_info['parallel']
        user_info['parallel'] = []
        begin
          session = BVT::Harness::CFSession.new(:admin => true,
                                                :email => user_info['admin']['email'],
                                                :passwd => user_info['admin']['passwd'],
                                                :target => user_info['target'])
        rescue Exception => e
          raise RuntimeError, "#{e.to_s}\nPlease input valid admin credential " +
              "for parallel running"
        end

        passwd = user_info['user']['passwd']
        (1..VCAP_BVT_PARALLEL_MAX_USERS).to_a.each do |index|
          email = "#{index}-#{user_info['user']['email']}"
          user  = session.user(email)
          user.create(passwd)
          config = {}
          config['email']   = user.email
          config['passwd']  = passwd
          user_info['parallel'] << config
        end
        File.open(VCAP_BVT_CONFIG_FILE, "w") { |f| f.write YAML.dump(user_info) }
      end
      user_info['parallel']
    end

    def init_sync_index
      File.open(VCAP_BVT_PARALLEL_SYNC_FILE, 'w') {|f| f.write("0")}
    end

    def increase_sync_index
      sync_index = 0
      File.open(VCAP_BVT_PARALLEL_SYNC_FILE, File::RDWR) do |f|
        f.flock(File::LOCK_EX)
        sync_index = f.read.to_i
        value = sync_index + 1
        f.rewind
        f.write("#{value}\n")
        f.flush
        f.truncate(f.pos)
        # wait 5 second to release lock
        # in order to ramp up multiple processes one by one
        sleep(5)
      end
      sync_index
    end

    def format_progress_output(tempfile)
      piece = ""
      until piece =~ /^Took/
        sleep(1) # read tempfile each 1 second
        if tempfile.eof?
          next
        end

        piece = tempfile.readline
        case piece
          when /^[.*F]+un.*$/ then
            print piece.gsub(/^([.*F]+)un.*$/, '\1').strip
          when /^[.*F]+$/ then
            print piece.gsub(/^([.*F]+)$/, '\1').strip
          when /^Took/
            puts ""
            return
          else
            # do nothing
        end
      end
    end

    SIXTY_SECONDS = 60
    def parse_output(tempfile)
      contents = {:pending => [],
                  :failure => {:details => [], :examples => []},
                  :time => "",
                  :summary => ""}
      tempfile.rewind
      until tempfile.eof?
        line = tempfile.readline
        case line
          when /^Pending:/ then
            while !(line =~ /^Finished in/) && !(line =~ /^Failures:$/)
              contents[:pending] << line
              line = tempfile.readline
            end
          when /^Failures:/ then
            until line =~ /^Finished in/
              contents[:failure][:details] << line
              line = tempfile.readline
            end
          when /^rspec .*/ then
            contents[:failure][:examples] << line
          else
            # do nothing
        end
      end

      # get time at last line
      tempfile.rewind
      data = tempfile.readlines
      time = data[-1].gsub(/^Took (\d+).\d+ seconds/, '\1').to_i
      contents[:time] += "Finished in #{time / SIXTY_SECONDS} minutes " +
          "#{time % SIXTY_SECONDS} seconds\n"

      # retrieve summary at last third line
      contents[:summary] = data[-3]

      format_output(contents)
    end

    def format_output(contents)
      data = []
      # pending case
      unless contents[:pending].empty?
        data += contents[:pending]
      end

      #Failure details
      unless contents[:failure][:details].empty?
        data += contents[:failure][:details]
      end

      # time and summary
      data << contents[:time] << contents[:summary]

      # failure examples
      unless contents[:failure][:examples].empty?
        data << "Failed examples:\n"
        data << contents[:failure][:examples]
      end

      data.each { |line| puts line}
      File.open(VCAP_BVT_ERROR_LOG, 'w') { |f| f.write(data.join(""))}
    end

    def run_tests
      number = ENV['VCAP_BVT_PARALLEL'].to_i
      number = VCAP_BVT_PARALLEL_MAX_USERS if number > VCAP_BVT_PARALLEL_MAX_USERS
      if number < 1
        raise RuntimeError, "user input #{yellow("VCAP_BVT_PARALLEL=" +
            "#{ENV['VCAP_BVT_PARALLEL']}")} is not valid. Please input " +
            "integer(1 - #{yellow(VCAP_BVT_PARALLEL_MAX_USERS)})"
      end
      create_parallel_users
      init_sync_index
      parallel_users = YAML.load_file(VCAP_BVT_CONFIG_FILE)['parallel']
      (0..number - 1).to_a.each { |index| puts "run parallel bvt via" +
                                    " #{yellow(parallel_users[index]['email'])}" }
      tempfile = Tempfile.new('output')
      cmd = "parallel_rspec -n #{number} -o '--tag ~admin' spec/ > #{tempfile.path}"
      io = IO.popen(cmd, :err => [:child, :out])
      format_progress_output(tempfile)
      parse_output(tempfile)
      tempfile.close
      tempfile.unlink
    end

    extend self
  end
end

