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

      @case_info_list = []
      @fr = File.new('./reports/junitResult.xml', 'w')
      @fr.puts "<?xml version='1.0' encoding='UTF-8'?>"
      @fr.puts "<result>"
      @fr.puts "<suites>"

      @lock = Mutex.new
      start_time = Time.now
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

            t1 = Time.now
            task_output = run_task(task, user['email'], user['passwd'])
            t2 = Time.now
            case_info = parse_case_log(task_output, task[:envs])
            unless case_info
              puts task_output
              next
            end
            case_info['duration'] = t2 - t1
            @case_info_list << case_info

            if case_info['status'] == 'fail'
              @lock.synchronize do
                failure_number += 1
                failure_list << [case_info, case_info['envs']]
                session = BVT::Harness::CFSession.new(:admin => false,
                                                :email => user['email'],
                                                :passwd => user['passwd'],
                                                :target => ENV['VCAP_BVT_TARGET'])
                session.log.error task_output

                # print failure immediately during the execution
                $stdout.print "\e[K"
                if failure_number == 1
                  $stdout.print "Failures:\n\n"
                end
                puts "  #{failure_number}) #{case_info['test_name']}"
                $stdout.print red(case_info['error_message'])
                $stdout.print cyan(case_info['error_stack_trace'])
                $stdout.print red("     (Envs: #{case_info['envs']})\n") if case_info['envs'] != ''
                $stdout.print red("     (Failure time: #{Time.now})\n\n")
              end
            elsif case_info['status'] == 'pending'
              @lock.synchronize do
                pending_number += 1
                pending_list << [case_info, case_info['envs']]
              end
            end
            case_number += 1
            pbar.inc
            pbar.instance_variable_set("@title", "#{pbar.current}/#{pbar.total}")
          end
        end
        # ramp up user threads one by one
        sleep 0.1
      end

      threads.each { |t| t.join }
      pbar.finish

      # print pending cases if configured
      if ENV['VCAP_BVT_SHOW_PENDING'] == 'true' && pending_number > 0
        $stdout.print "\n"
        puts "Pending:"
        pending_list.each {|pl|
          case_info = pl[0]
          envs = pl[1]
          puts "  #{yellow(case_info['test_name'])}\n"
          $stdout.print cyan(case_info['pending_info'])
          $stdout.print cyan("    (Envs: #{envs})\n") if envs != ''
        }
        $stdout.print "\n"
      end

      # print total time and summary result
      end_time = Time.now
      puts "Finished in #{format_time(end_time-start_time)}\n"
      if failure_number > 0
        $stdout.print red("#{case_number} examples, #{failure_number} failures")
        $stdout.print red(", #{pending_number} pending") if pending_number > 0
      elsif pending_number > 0
        $stdout.print yellow("#{case_number} examples, #{failure_number} failures, #{pending_number} pending")
      else
        $stdout.print green("#{case_number} examples, 0 failures")
      end
      $stdout.print "\n"

      # record failed rspec examples to rerun.sh
      unless failure_list.empty?
        rerun_file = File.new(VCAP_BVT_RERUN_FILE, 'w', 0777)
        $stdout.print "\nFailed examples:\n\n"
        failure_list.each do |fl|
          case_info = fl[0]
          env_vars = fl[1]
          rerun_file.puts "echo ----#{case_info['test_name']}"
          rerun_file.puts env_vars + case_info['rerun_cmd']
          $stdout.print red(env_vars + case_info['rerun_cmd'].split(' # ')[0])
          $stdout.print cyan(" # #{case_info['test_name']}")
          $stdout.print "\n"
        end
        rerun_file.close
      end

      generate_ci_report

      @fr.puts "</suites>"
      @fr.puts "<duration>#{end_time - start_time}</duration>"
      @fr.puts "<keepLongStdio>false</keepLongStdio>"
      @fr.puts "</result>"
      @fr.close
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
      cmd += ["bundle", "exec", "rspec", "-f", "d", "--color", task[:line]]
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

   def parse_case_log(str, envs)
      return nil if str =~ /0 examples/
      result = {}
      env_vars = ""
      if envs
        BVT::Spec::ServiceVersions.set_environment_variables(envs).each do |k, v|
          env_vars += "#{k}=\'#{v}\' "
        end
        env_vars = env_vars.strip
      end
      result['envs'] = env_vars
      logs = []
      str.each_line {|l| logs << l}

      stdout = ''
      unless logs[0].start_with? 'Run options:'
        clear_logs = []
        logs_start = false
        for i in 0..logs.length-1
          if logs[i].strip.start_with? 'Run options:'
            logs_start = true
          end
          if logs_start
            clear_logs << logs[i]
          else
            stdout += logs[i]
          end
        end
        logs = clear_logs
      end
      result['stdout'] = stdout

      result['class_name'] = logs[2].strip
      result['test_desc'] = logs[3].gsub(/\((FAILED|PENDING).+\)/, '').strip
      result['test_name'] = result['class_name'] + ' ' + result['test_desc']

      if logs[-1].include? '1 pending'
        result['status'] = 'pending'
        pending_info = ''
        for i in 7..logs.length-4
          next if logs[i].strip == ''
          pending_info += logs[i]
        end
        result['pending_info'] = pending_info
      elsif logs[-1].include? '0 failures'
        result['status'] = 'pass'
      elsif logs[-1].start_with? 'rspec '
        result['status'] = 'fail'
        result['rerun_cmd'] = logs[-1]
        error_message = logs[8]
        error_stack_trace = ''
        for i in 9..logs.length-8
          next if logs[i].strip == ''
          if logs[i].strip.start_with? '# '
            error_stack_trace += logs[i]
          else
            error_message += logs[i]
          end
        end
        error_message.each_line do |l|
          next if l.include? 'Error:'
          result['error_details'] = l.strip
          break
        end
        if error_message.index(result['error_details']) < error_message.length - result['error_details'].length - 10
          result['error_details'] += "..."
        end
        result['error_message'] = error_message
        result['error_stack_trace'] = error_stack_trace
      else
        result['status'] = 'unknown'
      end

      result
    end

    def generate_ci_report
      class_name_list = []
      @case_info_list.each do |case_info|
        class_name_list << case_info['class_name']
      end
      class_name_list.uniq!
      class_name_list.sort!
      class_name_list.each do |class_name|
        temp_case_info_list = []
        @case_info_list.each do |case_info|
          if case_info['class_name'] == class_name
            temp_case_info_list << case_info
          end
        end
        generate_single_file_report(temp_case_info_list)
      end
    end

    def generate_single_file_report(case_info_list)
      return if case_info_list == []
      class_name = case_info_list[0]['class_name']
      file_name = "./reports/#{class_name.gsub(/:+/, '-')}.xml"
      name = class_name.gsub(':', '_')

      suite_duration = 0.0
      fail_num = 0
      error_num = 0
      pending_num = 0
      stdout = ''
      stdout_list = []
      case_desc_list = []
      case_info_list.each do |case_info|
        suite_duration += case_info['duration']
        stdout_list << case_info['stdout']
        case_desc_list << case_info['test_desc'] + "@(" + case_info['envs']
        if case_info['status'] == 'fail'
          if case_info['error_message'].include? "expect"
            fail_num += 1
          else
            error_num += 1
          end
        elsif case_info['status'] == 'pending'
          pending_num += 1
        end
      end
      stdout_list.uniq!
      case_desc_list.sort!
      stdout_list.each {|s| stdout += s}

      @fr.puts "<suite>"
      @fr.puts "<file>#{file_name}</file>"
      @fr.puts "<name>#{name}</name>"
      @fr.puts "<stdout>"
      @fr.puts stdout.encode({:xml => :text}) if stdout.length > 0
      @fr.puts "</stdout>"
      @fr.puts "<stderr></stderr>"
      @fr.puts "<duration>#{suite_duration}</duration>"
      @fr.puts "<cases>"

      ff = File.new(file_name, 'w')
      ff.puts '<?xml version="1.0" encoding="UTF-8"?>'
      ff.puts "<testsuite name=\"#{class_name}\" tests=\"#{case_info_list.size}\" time=\"#{suite_duration}\" failures=\"#{fail_num}\" errors=\"#{error_num}\" skipped=\"#{pending_num}\">"

      case_desc_list.each do |case_desc_with_env|
        temp_list = case_desc_with_env.split('@(')
        case_desc = temp_list[0]
        envs = temp_list.length == 1 ? '' : temp_list[1]
        i = case_info_list.index {|c| c['test_desc'] == case_desc && c['envs'] == envs}
        case_info = case_info_list[i]
        test_name = case_info['test_name'].encode({:xml => :attr})
        test_name += " (PENDING)" if case_info['status'] == 'pending'
        test_name = envs + " - " + test_name if envs != ''
        @fr.puts "<case>"
        @fr.puts "<duration>#{case_info['duration']}</duration>"
        @fr.puts "<className>#{case_info['class_name']}</className>"
        @fr.puts "<testName>#{test_name}</testName>"
        @fr.puts "<skipped>#{case_info['status'] == 'pending'}</skipped>"
        @fr.puts "<envs>#{envs}</envs>"

        ff.puts "<testcase name=#{test_name.encode({:xml => :attr})} time=\"#{case_info['duration']}\">"
        ff.puts "<skipped/>" if case_info['status'] == 'pending'
        ff.puts "<envs>#{envs}</envs>"

        if case_info['status'] == 'fail'
          @fr.puts "<errorStackTrace>"
          @fr.puts case_info['error_message'].encode({:xml => :text}).gsub('Failure/Error: ', '')
          @fr.puts case_info['error_stack_trace'].encode({:xml => :text}).gsub('# ', '')
          @fr.puts "</errorStackTrace>"
          @fr.puts "<errorDetails>"
          @fr.puts case_info['error_details'].encode({:xml => :text})
          @fr.puts "</errorDetails>"

          if case_info['error_message'].include? "expected"
            type = "RSpec::Expectations::ExpectationNotMetError"
          elsif case_info['error_message'].include? "RuntimeError"
            type = "RuntimeError"
          else
            type = "UnknownError"
          end
          ff.puts "<failure type=\"#{type}\" message=#{case_info['error_details'].encode({:xml => :attr})}>"
          ff.puts case_info['error_message'].encode({:xml => :text}).gsub('Failure/Error: ', '')
          ff.puts case_info['error_stack_trace'].encode({:xml => :text}).gsub('# ', '')
          ff.puts "</failure>"
        end
        @fr.puts "<failedSince>0</failedSince>"
        @fr.puts "</case>"

        ff.puts "</testcase>"
      end

      @fr.puts "</cases>"
      @fr.puts "</suite>"

      ff.puts "<system-out>"
      ff.puts stdout.encode({:xml => :text}) if stdout.length > 0
      ff.puts "</system-out>"
      ff.puts "<system-err>"
      ff.puts "</system-err>"
      ff.puts "</testsuite>"
      ff.close
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
