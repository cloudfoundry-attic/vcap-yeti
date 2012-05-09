$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require "harness"

task :default => [:help]

desc "List help commands"
task :help do
  puts "Usage: rake [command]"
  puts "  tests\t\t\t\trun all bvts"
  puts "  admin\t\t\t\trun admin test cases"
  puts "  clean\t\t\t\tclean up test environment.\n" +
           "\t\t\t\t  1, Remove all apps and services under test user\n" +
           "\t\t\t\t  2, Remove all test users created in admin_user_spec.rb"
  puts "  java\t\t\t\trun java tests (spring, java_web)"
  puts "  jvm\t\t\t\trun jvm tests (spring, java_web, grails, lift)"
  puts "  ruby\t\t\t\trun ruby tests (rails3, sinatra, rack)"
  puts "  services\t\t\trun service tests (monbodb, redis, mysql, postgres, rabbitmq)"
  puts "  help\t\t\t\tlist help commands"
end

desc "Run the Basic Viability Tests"
task :tests do
  BVT::Harness::RakeHelper.generate_config_file
  BVT::Harness::RakeHelper.check_environment
  sh "bundle exec rspec spec/ --tag ~admin --format p -c | " +
         "tee #{File.join(BVT::Harness::VCAP_BVT_HOME, "error.log")}"
end

desc "Run admin test cases"
task :admin do
  BVT::Harness::RakeHelper.generate_config_file
  BVT::Harness::RakeHelper.check_environment
  sh "bundle exec rspec spec/users/ --tag admin --format p -c | " +
         "tee #{File.join(BVT::Harness::VCAP_BVT_HOME, "error.log")}"
end

desc "Run java tests (spring, java_web)"
task :java do
  puts "This task is under development, please stay tuned."
end

desc "Run jvm tests (spring, java_web, grails, lift)"
task :jvm do
  puts "This task is under development, please stay tuned."
end

desc "Run ruby tests (rails3, sinatra, rack)"
task :ruby do
  puts "This task is under development, please stay tuned."
end

desc "Run service tests (monbodb, redis, mysql, postgres, rabbitmq)"
task :services do
  puts "This task is under development, please stay tuned."
end

desc "Clean up test environment"
task :clean do
  BVT::Harness::RakeHelper.cleanup!
end

desc "sync yeti assets binaries"
task :sync_assets do
  BVT::Harness::RakeHelper.sync_assets
end
