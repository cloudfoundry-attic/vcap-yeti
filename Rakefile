$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require "harness"

task :default => [:help]

desc "List help commands"
task :help do
  puts "Usage: rake [command]"
  puts "  tests\t\trun all bvts\n" +
           "\t\tOptions:\n" +
           "\t\t  VCAP_BVT_PARALLEL=<NUMBER>, run bvts in parallel, "+
           "number range: 1-#{BVT::Harness::VCAP_BVT_PARALLEL_MAX_USERS}"
  puts "  random\trun all bvts randomly, add [N] to specify a seed"
  puts "  admin\t\trun admin test cases"
  puts "  clean\t\tclean up test environment.\n" +
           "\t\t  1, Remove all apps and services under test user\n" +
           "\t\t  2, Remove all test users created in admin_user_spec.rb"
  puts "  java\t\trun java tests (spring, java_web)"
  puts "  jvm\t\trun jvm tests (spring, java_web, grails, lift)"
  puts "  ruby\t\trun ruby tests (rails3, sinatra, rack)"
  puts "  services\trun service tests (monbodb, redis, mysql, postgres, rabbitmq, neo4j, vblob)"
  puts "  longevity\tloop the bvt tests, add [N] to specify loop times(default: 100)"
  puts "  help\t\tlist help commands"
end

desc "Run the Basic Verification Tests"
task :tests do
  BVT::Harness::RakeHelper.generate_config_file
  BVT::Harness::RakeHelper.check_environment
  if ENV['VCAP_BVT_PARALLEL']
    BVT::Harness::ParallelRunner.run_tests
  else
    BVT::Harness::RakeHelper.print_test_config
    sh("rspec spec/ --tag ~admin | tee #{BVT::Harness::VCAP_BVT_ERROR_LOG}")
  end
end

desc "Run all bvts randomly, add [N] to specify a seed"
task :random, :seed do |t, args|
  BVT::Harness::RakeHelper.generate_config_file
  BVT::Harness::RakeHelper.check_environment
  if args[:seed] != nil
    sh "bundle exec rspec spec/ --tag ~admin --seed #{args[:seed]} --format" +
       " d -c | tee #{File.join(BVT::Harness::VCAP_BVT_HOME, "error.log")}"
  else
    sh "bundle exec rspec spec/ --tag ~admin --order rand --format d -c | " +
       "tee #{File.join(BVT::Harness::VCAP_BVT_HOME, "error.log")}"
  end
end

desc "Run admin test cases"
task :admin do
  BVT::Harness::RakeHelper.generate_config_file(true)
  BVT::Harness::RakeHelper.check_environment
  sh "bundle exec rspec spec/users/ --tag admin --format p -c | " +
     "tee #{File.join(BVT::Harness::VCAP_BVT_HOME, "error.log")}"
end

desc "Run java tests (spring, java_web)"
task :java do
  BVT::Harness::RakeHelper.generate_config_file
  BVT::Harness::RakeHelper.check_environment
  sh "bundle exec rspec -P spec/**/*_spring_spec.rb,spec/**/*_java_web_spec.rb" +
     " --format d -c | tee #{File.join(BVT::Harness::VCAP_BVT_HOME, "error.log")}"
end

desc "Run jvm tests (spring, java_web, grails, lift)"
task :jvm do
  BVT::Harness::RakeHelper.generate_config_file
  BVT::Harness::RakeHelper.check_environment
  sh "bundle exec rspec -P spec/**/*_spring_spec.rb,spec/**/*_java_web_spec.rb," +
     "spec/**/*_grails_spec.rb,spec/**/*_lift_spec.rb --format d -c | tee " +
     "#{File.join(BVT::Harness::VCAP_BVT_HOME, "error.log")}"
end

desc "Run ruby tests (rails3, sinatra, rack)"
task :ruby do
  BVT::Harness::RakeHelper.generate_config_file
  BVT::Harness::RakeHelper.check_environment
  sh "bundle exec rspec -P spec/**/ruby18_*_spec.rb,spec/**/ruby19_*_spec.rb" +
     " --format d -c | tee #{File.join(BVT::Harness::VCAP_BVT_HOME, "error.log")}"
end

desc "Run service tests (mongodb, redis, mysql, postgres, rabbitmq, neo4j, vblob)"
task :services do
  BVT::Harness::RakeHelper.generate_config_file
  BVT::Harness::RakeHelper.check_environment
  sh "bundle exec rspec spec/ --tag mongodb --tag rabbitmq --tag mysql --tag " +
     "redis --tag postgresql --tag neo4j --tag vblob --format d -c | tee " +
     File.join(BVT::Harness::VCAP_BVT_HOME, "error.log")
end

desc "Clean up test environment"
task :clean do
  BVT::Harness::RakeHelper.cleanup!
end

desc "sync yeti assets binaries"
task :sync_assets do
  BVT::Harness::RakeHelper.sync_assets
end

desc "continuously loop the bvt tests"
task :longevity, :looptimes do |t, args|
  loop_times = 100
  time_start = Time.now
  if args[:looptimes] != nil && args[:looptimes].to_i > 0
    loop_times = args[:looptimes].to_i
  end
  puts "loop times: #{loop_times}"
  $stdout.flush
  loop_times.times {|i|
    BVT::Harness::RakeHelper.generate_config_file
    BVT::Harness::RakeHelper.check_environment
    cmd = "bundle exec rspec spec/ --tag ~admin --format p -c | " +
       "tee #{File.join(BVT::Harness::VCAP_BVT_HOME, "error.log")}"
    output = %x[#{cmd}]
    puts output
    if output.include? "Failures:"
      t1 = Time.now
      running_time = (t1 - time_start).to_i
      puts "Task failed!"
      puts "longevity task has succeeded for #{i} times"
      puts "longevity task has been running for #{running_time} seconds"
      break
    end
    t2 = Time.now
    running_time = (t2 - time_start).to_i
    puts "Task succeeded!"
    puts "longevity task has succeeded for #{i+1} times"
    puts "longevity task has been running for #{running_time} seconds"
    $stdout.flush
  }
end
