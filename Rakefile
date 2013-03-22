$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require 'rspec/core/rake_task'
require "harness"
include BVT::Harness
include BVT::Harness::ColorHelpers

task :default => [:full]

desc "run full tests in parallel, e.g. rake full[5] (default to 10, max = 16)"
task :full, :thread_number do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  create_reports_folder
  longevity(threads, {'tags' => '~admin'})
end

desc "run java tests (spring, java_web) in parallel, e.g. rake java[5] (default to 10, max = 16)"
task :java, :thread_number, :longevity, :fail_fast do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  create_reports_folder
  longevity(threads, {'pattern' => /_(spring|java_web)_spec\.rb/})
end

desc "tests (spring, java_web, grails, lift) in parallel e.g. rake jvm[5] (default to 10, max = 16)"
task :jvm, :thread_number do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  create_reports_folder
  longevity(threads, {'pattern' => /_(spring|java_web|grails|lift)_spec\.rb/})
end

desc "run ruby tests (rails3, sinatra, rack) in parallel e.g. rake ruby[5] (default to 10, max = 16)"
task :ruby, :thread_number do |t, args|
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  create_reports_folder
  longevity(threads, {'pattern' => /ruby_.+_spec\.rb/})
end

desc "run service tests (mongodb/redis/mysql/postgres/rabbitmq/neo4j/vblob) in parallel e.g. rake services[5] (default to 10, max = 16)"
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

desc <<-CLEAN
clean up test environment(only run this task after interruption).
  1, Remove all apps and services under test user
  2, Remove all apps and services under parallel users
CLEAN
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

desc "delete yeti-like organizations"
task :delete_orgs do
  sh "./tools/scripts/yeti-hunter.rb"
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
  ENV['VCAP_BVT_LONGEVITY'] ? ENV['VCAP_BVT_LONGEVITY'].to_i : 1
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
