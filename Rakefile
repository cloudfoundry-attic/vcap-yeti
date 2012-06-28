$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require "harness"

task :default => [:help]

desc "List help commands"
task :help do
  puts "Usage: rake [command]"
  puts "  admin\t\trun admin test cases"
  puts "  tests\t\trun core tests in parallel, e.g. rake test[5] (default to 10, max = 16)"
  puts "  full\t\trun full tests in parallel, e.g. rake full[5] (default to 10, max = 16)"
  puts "  random\trun all bvts randomly, e.g. rake random[1023] to re-run seed 1023"
  puts "  longevity\tloop bvt tests, e.g. rake longevity[10] (default to 100)"
  puts "  java\t\trun java tests (spring, java_web) in parallel\n" +
          "\t\te.g. rake java[5] (default to 10, max = 16)"
  puts "  jvm\t\trun jvm tests (spring, java_web, grails, lift) in parallel\n" +
          "\t\te.g. rake jvm[5] (default to 10, max = 16)"
  puts "  ruby\t\trun ruby tests (rails3, sinatra, rack) in parallel\n" +
          "\t\te.g. rake ruby[5] (default to 10, max = 16)"
  puts "  services\trun service tests (mongodb/redis/mysql/postgres/rabbitmq/neo4j/vblob) in parallel\n" +
          "\t\te.g. rake services[5] (default to 10, max = 16)"
  puts "  clean\t\tclean up test environment(only run this task after interruption).\n" +
           "\t\t  1, Remove all apps and services under test user\n" +
           "\t\t  2, Remove all test users created in admin_user_spec.rb"
  puts "  help\t\tlist help commands"
end

desc "run full tests (not include admin cases)"
task :full, :thread_number do |t, args|
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  if threads == 1
    BVT::Harness::RakeHelper.generate_config_file
    BVT::Harness::RakeHelper.check_environment
    sh("rspec --format Fuubar --color spec/ --tag ~admin")
  else
    BVT::Harness::RakeHelper.generate_config_file(true)
    BVT::Harness::RakeHelper.check_environment
    BVT::Harness::ParallelHelper.run_tests(threads, {"tags" => "~admin"})
  end
end

desc "run tests subset"
task :tests, :thread_number do |t, args|
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  if threads == 1
    BVT::Harness::RakeHelper.generate_config_file
    BVT::Harness::RakeHelper.check_environment
    sh("rspec --format Fuubar --color spec/ --tag ~admin --tag p1")
  else
    BVT::Harness::RakeHelper.generate_config_file(true)
    BVT::Harness::RakeHelper.check_environment
    BVT::Harness::ParallelHelper.run_tests(threads, {"tags" => "p1,~admin"})
  end
end

desc "Run all bvts randomly, add [N] to specify a seed"
task :random, :seed do |t, args|
  BVT::Harness::RakeHelper.generate_config_file
  BVT::Harness::RakeHelper.check_environment
  if args[:seed] != nil
    sh "bundle exec rspec spec/ --tag ~admin --tag p1" +
       " --seed #{args[:seed]} --format d -c"
  else
    sh "bundle exec rspec spec/ --tag ~admin --tag p1" +
       "--order rand --format d -c"
  end
end

desc "Run admin test cases"
task :admin do
  BVT::Harness::RakeHelper.generate_config_file(true)
  BVT::Harness::RakeHelper.check_environment
  sh "bundle exec rspec --format Fuubar --color spec/users/ --tag admin"
end

desc "Run java tests (spring, java_web)"
task :java, :thread_number do |t, args|
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  if threads == 1
    BVT::Harness::RakeHelper.generate_config_file
    BVT::Harness::RakeHelper.check_environment
    sh "bundle exec rspec --format Fuubar --color -P spec/**/*_spring_spec.rb," +
     "spec/**/*_java_web_spec.rb"
  else
    BVT::Harness::RakeHelper.generate_config_file(true)
    BVT::Harness::RakeHelper.check_environment
    BVT::Harness::ParallelHelper.run_tests(threads, {"pattern" => /_(spring|java_web)_spec\.rb/})
  end
end

desc "Run jvm tests (spring, java_web, grails, lift)"
task :jvm, :thread_number do |t, args|
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  if threads == 1
    BVT::Harness::RakeHelper.generate_config_file
    BVT::Harness::RakeHelper.check_environment
    sh "bundle exec rspec --format Fuubar --color -P spec/**/*_spring_spec.rb,spec" +
     "/**/*_java_web_spec.rb,spec/**/*_grails_spec.rb,spec/**/*_lift_spec.rb"
  else
    BVT::Harness::RakeHelper.generate_config_file(true)
    BVT::Harness::RakeHelper.check_environment
    BVT::Harness::ParallelHelper.run_tests(threads,
      {"pattern" => /_(spring|java_web|grails|lift)_spec\.rb/})
  end
end

desc "Run ruby tests (rails3, sinatra, rack)"
task :ruby, :thread_number do |t, args|
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  if threads == 1
    BVT::Harness::RakeHelper.generate_config_file
    BVT::Harness::RakeHelper.check_environment
    sh "bundle exec rspec --format Fuubar --color -P spec/**/ruby18_*_spec.rb," +
     "spec/**/ruby19_*_spec.rb"
  else
    BVT::Harness::RakeHelper.generate_config_file(true)
    BVT::Harness::RakeHelper.check_environment
    BVT::Harness::ParallelHelper.run_tests(threads, {"pattern" => /ruby1[89]_.+_spec\.rb/})
  end
end

desc "Run service tests (mongodb, redis, mysql, postgres, rabbitmq, neo4j, vblob)"
task :services, :thread_number do |t, args|
  threads = 10
  threads = args[:thread_number].to_i if args[:thread_number]
  if threads == 1
    BVT::Harness::RakeHelper.generate_config_file
    BVT::Harness::RakeHelper.check_environment
    sh "bundle exec rspec --format Fuubar --color spec/ --tag mongodb --tag rabbitmq " +
     "--tag mysql --tag redis --tag postgresql --tag neo4j --tag vblob"
  else
    BVT::Harness::RakeHelper.generate_config_file(true)
    BVT::Harness::RakeHelper.check_environment
    BVT::Harness::ParallelHelper.run_tests(threads, {"tags" =>
      "~admin,mongodb,rabbitmq,mysql,redis,postgresql,neo4j,vblob"})
  end
end

desc "Clean up test environment"
task :clean do
  BVT::Harness::RakeHelper.cleanup!
end

desc "sync yeti assets binaries"
task :sync_assets do
  BVT::Harness::RakeHelper.sync_assets
end

desc "longevity bvt tests"
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
    cmd = "bundle exec rspec --format Fuubar --color spec/ --tag ~admin --tag p1"
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
