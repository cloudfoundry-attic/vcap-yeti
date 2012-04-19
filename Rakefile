$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require "harness"

task :default => [:help]

desc "List help commands"
task :help do
  puts "Usage: rake [command]"
  puts "  tests\t\t\t\trun all bvts"
  puts "  help\t\t\t\tlist help commands"
end

desc "Run the Basic Viability Tests"
task :tests do
  BVT::Harness::RakeHelper.generate_config_file
  BVT::Harness::RakeHelper.check_environment
  sh "bundle exec rspec spec/ --format p -c | tee #{File.join(BVT::Harness::VCAP_BVT_HOME, "error.log")}"
end
