$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require "rspec/core/rake_task"
require "harness"
include BVT::Harness

task :default => :full

desc "run full tests in parallel, e.g. rake full[5] (default to 10, max = 16)"
task :full, :thread_number do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  RakeHelper.run(threads, {'tags' => '~admin'})
end

desc "run java tests (spring, java_web) in parallel, e.g. rake java[5] (default to 10, max = 16)"
task :java, :thread_number, :longevity, :fail_fast do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  RakeHelper.run(threads, {'pattern' => /_(spring|java_web)_spec\.rb/})
end

desc "tests (spring, java_web, grails, lift) in parallel e.g. rake jvm[5] (default to 10, max = 16)"
task :jvm, :thread_number do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  RakeHelper.run(threads, {'pattern' => /_(spring|java_web|grails|lift)_spec\.rb/})
end

desc "run ruby tests (rails3, sinatra, rack) in parallel e.g. rake ruby[5] (default to 10, max = 16)"
task :ruby, :thread_number do |t, args|
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)
  RakeHelper.run(threads, {'pattern' => /ruby_.+_spec\.rb/})
end

desc "run service tests (mongodb/redis/mysql/postgres/rabbitmq/neo4j/vblob) in parallel e.g. rake services[5] (default to 10, max = 16)"
task :services, :thread_number do |t, args|
  RakeHelper.sync_assets
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  RakeHelper.prepare_all(threads)

  if ENV["VCAP_BVT_SERVICE"]
    RakeHelper.run(threads, {'tags' => "~admin,#{ENV["VCAP_BVT_SERVICE"].downcase}"})
  else
    RakeHelper.run(threads, {'tags' => '~admin,mongodb,rabbitmq,mysql,redis,postgresql,neo4j,vblob'})
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

desc "sync yeti assets binaries"
task :sync_assets do
  RakeHelper.sync_assets
end

desc "delete yeti-like organizations"
task :delete_orgs do
  sh "./tools/scripts/yeti-hunter.rb"
end
