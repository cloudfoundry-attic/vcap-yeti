$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require 'rspec/core/rake_task'
require "harness"
include BVT::Harness
include BVT::Harness::ColorHelpers

task :default => [:help]

desc "List help commands"
task :help do
  puts "Usage: rake [command]"
  puts "  admin\t\trun admin test cases"
  puts "  tests\t\trun core tests in parallel, e.g. rake test[5] (default to 10, max = 16)\n"
  puts "       \t\tOptions: VCAP_BVT_LONGEVITY=N can loop this task.\n"
  puts "       \t\te.g. rake tests[8] VCAP_BVT_LONGEVITY=10"
  puts "       \t\tVCAP_BVT_CONFIG_FILE=[path_to_config_file] to specify config file.\n"
  puts "       \t\te.g. rake tests VCAP_BVT_CONFIG_FILE=/home/czhang/my_test.yml\n"
  puts "       \t\tAbove options are also usable in other tasks."
  puts "  full\t\trun full tests in parallel, e.g. rake full[5] (default to 10, max = 16)"
  puts "  random\trun all bvts randomly, e.g. rake random[1023] to re-run seed 1023"
  puts "  java\t\trun java tests (spring, java_web) in parallel\n" +
          "\t\te.g. rake java[5] (default to 10, max = 16)"
  puts "  jvm\t\trun jvm tests (spring, java_web, grails, lift) in parallel\n" +
          "\t\te.g. rake jvm[5] (default to 10, max = 16)"
  puts "  ruby\t\trun ruby tests (rails3, sinatra, rack) in parallel\n" +
          "\t\te.g. rake ruby[5] (default to 10, max = 16)"
  puts "  services\trun service tests (mongodb/redis/mysql/postgres/rabbitmq/neo4j/vblob) in parallel\n" +
          "\t\te.g. rake services[5] (default to 10, max = 16)"
  puts "  core\t\trun core tests for verifying that an installation meets\n" +
       "\t\tminimal Cloud Foundry compatibility requirements"
  puts "  mcf\t\trun Micro Cloud Foundry tests\n"
  puts "  clean\t\tclean up test environment(only run this task after interruption).\n" +
           "\t\t  1, Remove all apps and services under test user\n" +
           "\t\t  2, Remove all apps and services under parallel users"
  puts "  rerun\t\trerun failed cases of the previous run\n"
  puts "  help\t\tlist help commands"
end

desc "run full tests (not include admin cases)"
task :full, :thread_number do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  create_reports_folder
  longevity(threads, {'tags' => '~admin'})
end

desc "run tests (don't include admin and slow cases)"
task :fast, :thread_number do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  create_reports_folder
  longevity(threads, {'tags' => '~admin,~slow'})
end

desc "run tests subset"
task :tests, :thread_number do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  create_reports_folder
  longevity(threads, {'tags' => 'p1,~admin,~slow'})
end

desc "Run all bvts randomly, add [N] to specify a seed"
task :random, :seed do |t, args|
  RakeHelper.sync_assets
  if args[:seed] != nil
    sh "bundle exec rspec spec/ --tag ~admin --tag ~slow" +
       " --seed #{args[:seed]} --format d -c"
  else
    sh "bundle exec rspec spec/ --tag ~admin --tag ~slow" +
       " --order rand --format d -c"
  end
end

desc "Run admin test cases"
task :admin do
  RakeHelper.prepare_all
  create_reports_folder
  longevity(1, {'tags' => 'admin'})
end

desc "Run java tests (spring, java_web)"
task :java, :thread_number, :longevity, :fail_fast do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  create_reports_folder
  longevity(threads, {'pattern' => /_(spring|java_web)_spec\.rb/})
end

desc "Run jvm tests (spring, java_web, grails, lift)"
task :jvm, :thread_number do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  create_reports_folder
  longevity(threads, {'pattern' => /_(spring|java_web|grails|lift)_spec\.rb/})
end

desc "Run ruby tests (rails3, sinatra, rack)"
task :ruby, :thread_number do |t, args|
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  create_reports_folder
  longevity(threads, {'pattern' => /ruby_.+_spec\.rb/})
end

desc "Run service tests (mongodb, redis, mysql, postgres, rabbitmq, neo4j, vblob)"
task :services, :thread_number do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  create_reports_folder
  if ENV["VCAP_BVT_SERVICE"]
    longevity(threads, {'tags' => "~admin,#{ENV["VCAP_BVT_SERVICE"].downcase}"})
  else
    longevity(threads, {'tags' => '~admin,mongodb,rabbitmq,mysql,redis,postgresql,neo4j,vblob'})
  end
end

desc "Clean up test environment"
task :clean do
  RakeHelper.cleanup!
end

desc "rerun failed cases of the previous run"
task :rerun, :thread_number do |t, args|
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  if File.directory?("./reports")
    longevity(threads, nil, true)
  else
    puts yellow('no reports folder found')
  end
end

task :rerun_failure, :thread_number do |t, args|
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  if File.directory?("./reports")
    longevity(threads, nil, true)
  else
    puts yellow('no reports folder found')
  end
end

desc "sync yeti assets binaries"
task :sync_assets do
  RakeHelper.sync_assets
end

desc 'run core tests for verifying that an installation meets minimal Cloud Foundry compatibility requirements'
RSpec::Core::RakeTask.new(:core) do |t|
  t.rspec_opts = '--tag cfcore'
end

desc 'run Micro Cloud Foundry tests'
RSpec::Core::RakeTask.new(:mcf) do |t|
  t.rspec_opts = '--tag mcf'
end

def create_reports_folder
  output = `ls .`
  if output.include? 'reports'
    `rm -rf reports/*`
  else
    `mkdir reports`
  end
end

def get_longevity_number
  return ENV['VCAP_BVT_LONGEVITY'].to_i if ENV['VCAP_BVT_LONGEVITY']
  return 1
end

def longevity(threads, filter, rerun=false)
  loop_number = get_longevity_number
  if loop_number == 1
    result = ParallelHelper.run_tests(threads, filter, rerun)
    if result[:interrupted] || result[:failure_number] > 0
      exit(1)
    else
      exit(0)
    end
  elsif loop_number < 0
    puts red("longevity input error")
    exit(1)
  end
  total_case_number = 0
  total_failure_number = 0
  total_pending_number = 0
  time_start = Time.now
  puts yellow("loop number: #{loop_number}")
  $stdout.flush
  actual_loop_number = 1
  result = nil
  while TRUE
    puts yellow("This is run: #{actual_loop_number}")
    begin
      result = ParallelHelper.run_tests(threads, filter, rerun)
      total_case_number += result[:case_number]
      total_failure_number += result[:failure_number]
      total_pending_number += result[:pending_number]
      break if result[:interrupted]
    rescue Exception => e
      puts e.to_s
      sleep 180
    end
    break if actual_loop_number == loop_number
    actual_loop_number += 1
  end
  puts yellow("longevity finished!")
  puts yellow("loops: #{actual_loop_number}")
  t1 = Time.now
  running_time = (t1 - time_start).to_i
  puts yellow("duration: #{running_time}s")
  puts "examples: #{total_case_number}"
  puts red("failures: #{total_failure_number}")
  puts yellow("pending: #{total_pending_number}")

  if result == nil || result[:interrupted] || total_failure_number > 0
    exit(1)
  else
    exit(0)
  end
end

