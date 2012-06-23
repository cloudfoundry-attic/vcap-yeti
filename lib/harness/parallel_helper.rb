require 'progressbar'

module BVT::Harness
  module ParallelHelper
    include Interactive, ColorHelpers

    SPEC_PATH = File.join(File.dirname(__FILE__), "../../spec/")

    def create_parallel_users
      user_info = RakeHelper.get_config
      unless user_info['parallel']
        unless user_info['admin']
          puts "please input admin account to create concurrent users"
          BVT::Harness::RakeHelper::generate_config_file(true)
          user_info = RakeHelper.get_config
        end

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
          puts "create user: #{yellow(config['email'])}"
          user_info['parallel'] << config
        end
        File.open(VCAP_BVT_CONFIG_FILE, "w") { |f| f.write YAML.dump(user_info) }
      end
      user_info['parallel']
    end

    def run_tests(thread_number, options = {"tags" => "~admin"})
      if thread_number > VCAP_BVT_PARALLEL_MAX_USERS
        puts red("threads_number can't be greater than #{VCAP_BVT_PARALLEL_MAX_USERS}")
        return
      end
      @lock = Mutex.new
      t1 = Time.now
      all_users = create_parallel_users
      parallel_users = []
      i = 0
      all_users.each {|user|
        parallel_users << user
        i += 1
        break if i == thread_number
      }
      puts yellow("threads number: #{thread_number}\n")
      parse_case_list(options)
      pbar = ProgressBar.new("0/#{@queue.size}", @queue.size, $stdout)
      pbar.format_arguments = [:title, :percentage, :bar, :stat]
      case_number = 0
      failure_number = 0
      pending_number = 0
      failure_list = []
      pending_list = []

      Thread.abort_on_exception = false
      threads = []

      parallel_users.each do |user|
        threads << Thread.new do
          until @queue.empty?
            task = @queue.pop

            task_output = run_task(task, user['email'], user['passwd'])

            if task_output =~ /Failures/
              failure_number += 1
              failure_list << [task, parse_failure_log(task_output)]
              @lock.synchronize do
                $stdout.print "\e[K"
                if failure_number == 1
                  puts "Failures:"
                end
                puts "  #{failure_number}) #{parse_failure_log(task_output)}\n\n"
              end
            elsif task_output =~ /Pending/
              pending_number += 1
              pending_list << [task, parse_pending_log(task_output)]
            end
            case_number += 1
            pbar.inc
            pbar.instance_variable_set("@title", "#{pbar.current}/#{pbar.total}")
            # add think time when finishing every task
            sleep 0.1
          end
        end
        # ramp up user threads one by one
        sleep 0.1
      end

      threads.each { |t| t.join }
      pbar.finish

      $stdout.print "\n\n"
      t2 = Time.now
      $stdout.print green("Finished in #{format_time(t2-t1)}\n")
      if failure_number > 0
        $stdout.print red("#{case_number} examples, #{failure_number} failures")
        $stdout.print red(", #{pending_number} pending") if pending_number > 0
      else
        $stdout.print yellow("#{case_number} examples, #{failure_number} failures")
        $stdout.print yellow(", #{pending_number} pending") if pending_number > 0
      end
      $stdout.print "\n"

      unless failure_list.empty?
        $stdout.print "\nFailed examples:\n\n"
        failure_list.each_with_index do |log, i|
          case_desc = ''
          log[1].each_line {|line|
             case_desc = line
             break
          }
          rerun_cmd = 'rspec .' + log[0].match(/\/spec\/.*_spec\.rb:\d{1,4}/).to_s
          $stdout.print red(rerun_cmd)
          $stdout.print cyan(" # #{case_desc}")
        end
        $stdout.print "\n"
      end
    end

    def get_case_list
      file_list = `grep -rl '' #{SPEC_PATH}`
      case_list = []
      file_list.each_line { |filename|
        unless filename.include? "_spec.rb"
          next
        end
        f = File.read(filename.strip)
        cases = f.scan(/it [\s\S]*? do/)
        line_number = 0
        cases.each { |c|
          tags = []
          draft_tags = c.scan(/:([a-zA-Z0-9_]+)/)
          draft_tags.each { |tag|
            tags << tag[0]
          }
          case_desc = c.scan(/it\s+['"](.*?)['"]/)[0][0]
          i = 0
          cross_line = false
          f.each_line { |line|
            i += 1
            if i <= line_number && line_number > 0
              next
            end
            if line.include? case_desc
              if line.strip.end_with? " do"
                case_hash = {"line" => "#{filename.strip}:#{i}", "tags" => tags}
                case_list << case_hash
                line_number = i
                cross_line = false
                break
              else
                cross_line = true
              end
            end
            if cross_line && (line.strip.end_with? " do")
              case_hash = {"line" => "#{filename.strip}:#{i}", "tags" => tags}
              case_list << case_hash
              line_number = i
              cross_line = false
              break
            end
          }
        }
      }
      case_list
    end

    def parse_case_list(options)
      @queue = Queue.new
      all_case_list = get_case_list
      pattern_filter_list = []
      tags_filter_list = []

      if options["pattern"]
        all_case_list.each { |c|
          if c["line"].match(options["pattern"])
            pattern_filter_list << c
          end
        }
      else
        pattern_filter_list = all_case_list
      end

      if options["tags"]
        include_tags = []
        exclude_tags = []
        all_tags = options["tags"].split(",")
        all_tags.each { |tag|
          if tag.start_with? "~"
            exclude_tags << tag.gsub("~", "")
          else
            include_tags << tag
          end
        }
        pattern_filter_list.each { |c|
          if (include_tags.length == 0 || (c["tags"] - include_tags).length < c["tags"].length) &&
            ((c["tags"] - exclude_tags).length == c["tags"].length)
            tags_filter_list << c
          end
        }
      else
        tags_filter_list = pattern_filter_list
      end
      tags_filter_list.each { |t|
        @queue << t["line"]
      }
    end

    def run_task(task, user, password)
      cmd = [] # Preparing command for popen

      env_extras = {
        "YETI_PARALLEL_USER" => user,
        "YETI_PARALLEL_USER_PASSWD" => password
      }

      cmd << ENV.to_hash.merge(env_extras)
      cmd += ["bundle", "exec", "rspec", "--color", task]
      cmd

      output = ""

      IO.popen(cmd, :err => [:child, :out]) do |io|
        output << io.read
      end

      output
    end

    def format_time(t)
      time_str = ''
      time_str += (t / 3600).to_i.to_s + " hours " if t > 3600
      time_str += (t % 3600 / 60).to_i.to_s + " minutes " if t > 60
      time_str += (t % 60).to_f.round(2).to_s + " seconds"
      time_str
    end

    def parse_failure_log(str)
      index1 = str.index('1) ')
      index2 = str.index('Finished in')
      output = ""
      temp = str.slice(index1+3..index2-1).strip
      temp.each_line { |line|
        if line.strip.start_with? "BVT::Spec::"
          output += line
        elsif line.strip.start_with? "# "
          output += cyan(line)
        else
          output += red(line)
        end
      }
      output
    end

    def parse_pending_log(str)
      index1 = str.index('Pending:')
      index2 = str.index('Finished in')
      str.slice(index1+8..index2-1).strip
    end

    extend self
  end
end
