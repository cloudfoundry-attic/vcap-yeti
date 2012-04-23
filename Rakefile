$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require "harness"

task :default => [:help]

desc "List help commands"
task :help do
  puts "Usage: rake [command]"
  puts "  tests\t\t\t\trun all bvts"
  puts "  clean\t\t\t\tdelete apps and services"
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
  sh "bundle exec rspec spec/ --format p -c | tee #{File.join(BVT::Harness::VCAP_BVT_HOME, "error.log")}"
end

desc "Delete apps and services"
task :clean do
  puts "This task is under development, please stay tuned."
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

