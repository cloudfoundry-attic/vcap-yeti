require 'progressbar'
require 'harness'

module BVT::Harness
  module ParallelHelper
    include Interactive, ColorHelpers

    SPEC_PATH = File.join(File.dirname(__FILE__), "../../spec/")

    def create_parallel_users
      user_info = RakeHelper.get_config
      unless user_info['parallel']
        unless user_info['admin']
          puts "please input admin account to create concurrent users"
          BVT::Harness::RakeHelper::get_admin_user
          BVT::Harness::RakeHelper::get_admin_user_passwd
          BVT::Harness::RakeHelper::save_config
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

        passwd = 'aZ_x13YcIa4nhl' # parallel user secret
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
        multi_target_config = YAML.load_file(VCAP_BVT_CONFIG_FILE)
        target = user_info['target']
        user_info['admin'].delete('passwd')
        multi_target_config[target]['admin']    = user_info['admin']
        multi_target_config[target]['parallel'] = user_info['parallel']
        File.open(VCAP_BVT_CONFIG_FILE, "w") { |f| f.write YAML.dump(multi_target_config) }
      end
      user_info['parallel']
    end

    def run_tests(thread_number, options = {"tags" => "~admin"})
      if thread_number > VCAP_BVT_PARALLEL_MAX_USERS
        puts red("threads_number can't be greater than #{VCAP_BVT_PARALLEL_MAX_USERS}")
        return
      elsif thread_number < 1
        puts red("threads_number can't be less than 1")
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
      @queue = Queue.new
      parse_case_list(options)

      # insert service versions cases in @queue
      services = BVT::Spec::ServiceVersions.get_tested_services()
      services.each do |m|
        m[:versions].each do |v|
          parse_case_list({"tags" => m[:vendor]},
                          {:vendor => m[:vendor], :version => v})
        end
      end

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
              failure_log = parse_failure_log(task_output)
              failure_list << [task[:line], failure_log, task[:envs]]
              @lock.synchronize do
                session = BVT::Harness::CFSession.new(:admin => false,
                                                :email => user['email'],
                                                :passwd => user['passwd'],
                                                :target => ENV['VCAP_BVT_TARGET'])
                session.log.error failure_log
                $stdout.print "\e[K"
                if failure_number == 1
                  puts "Failures:"
                end
                puts "  #{failure_number}) #{failure_log}\n"
                puts red("     (Failure time: #{Time.now})\n\n")
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

      $stdout.print "\n"
      if ENV['VCAP_BVT_SHOW_PENDING'] == 'true'
        if pending_number > 0
          puts "Pending:"
          pending_list.each {|p|
            puts "  #{p[1]}\n"
          }
        end
      end
      $stdout.print "\n"
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
        rerun_file = File.new(VCAP_BVT_RERUN_FILE, 'w', 0777)
        $stdout.print "\nFailed examples:\n\n"
        failure_list.each_with_index do |log, i|
          case_desc = ''
          log[1].each_line {|line|
             case_desc = line
             break
          }
          env_vars = ""
          if log[2]
            BVT::Spec::ServiceVersions.set_environment_variables(log[2]).each do |k, v|
              env_vars += "#{k}=\'#{v}\' "
            end
          end

          rerun_cmd = "#{env_vars}" + 'rspec .' + log[0].match(/\/spec\/.*_spec\.rb:\d{1,4}/).to_s
          rerun_file.puts rerun_cmd
          $stdout.print red(rerun_cmd)
          $stdout.print cyan(" # #{case_desc}")
        end
        rerun_file.close
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

        # try to get tags of describe level
        describe_text = f.scan(/describe [\s\S]*? do/)[0]
        describe_tags = []
        temp = describe_text.scan(/[,\s]:(\w+)/)
        unless temp == nil
          temp.each do |t|
            describe_tags << t[0]
          end
        end

        # get cases of normal format: "it ... do"
        cases = f.scan(/(it (["'])([\s\S]*?)\2[\s\S]*? do)/)
        line_number = 0
        if cases
          cases.each { |c1|
            c = c1[0]
            tags = []
            draft_tags = c.scan(/[,\s]:(\w+)/)
            draft_tags.each { |tag|
              tags << tag[0]
            }
            tags += describe_tags
            tags.uniq

            i = 0
            cross_line = false
            f.each_line { |line|
              i += 1
              if i <= line_number && line_number > 0
                next
              end
              if line.include? c1[2]
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
        end

        # get cases of another format: "it {...}"
        cases = f.scan(/it \{[\s\S]*?\}/)
        line_number = 0
        if cases
          cases.each { |c|
            i = 0
            f.each_line { |line|
              i += 1
              if i <= line_number && line_number > 0
                next
              end
              if line.include? c
                case_hash = {"line" => "#{filename.strip}:#{i}", "tags" => describe_tags}
                case_list << case_hash
                line_number = i
                break
              end
            }
          }
        end
      }
      case_list
    end

    def parse_case_list(options, envs = nil)
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
      # rails console doesn't support parallel, so arrange rails console cases dispersively
      total_number = tags_filter_list.size
      rails_console_list = []

      for i in 0..total_number-1
        t = tags_filter_list[i]["line"]
        if t.include? "rails_console"
          rails_console_list << i
        end
      end
      rails_console_number = rails_console_list.size
      if rails_console_number > 1
        mod = total_number / rails_console_number
        for i in 0..rails_console_number-1
          swap(tags_filter_list, i * mod, rails_console_list[i])
        end
      end

      tags_filter_list.each { |t|
        @queue << {:line => t["line"], :envs => envs}
      }
    end

    def swap(a, i1, i2)
      temp = a[i1]
      a[i1] = a[i2]
      a[i2] = temp
    end

    def run_task(task, user, password)
      cmd = [] # Preparing command for popen

      env_extras = {
        "YETI_PARALLEL_USER" => user,
        "YETI_PARALLEL_USER_PASSWD" => password
      }
      env_extras = env_extras.merge(
          BVT::Spec::ServiceVersions.set_environment_variables(task[:envs])) if task[:envs]

      cmd << ENV.to_hash.merge(env_extras)
      cmd += ["bundle", "exec", "rspec", "--color", task[:line]]
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
      output = ""
      temp = str.slice(index1+8..index2-1).strip
      temp.each_line { |line|
        if line.strip.start_with? "BVT::Spec::"
          output += yellow(line)
        elsif line.strip.start_with? "# "
          output += cyan(line)
        else
          output += line
        end
      }
      output
    end

    extend self
  end
end
