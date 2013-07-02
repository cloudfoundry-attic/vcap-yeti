$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require "rspec/core/rake_task"
require "harness"
include BVT::Harness

desc "Prepare for running parallel specs"
task :prepare => [:build_test_apps, "users:create"]

namespace :users do
  desc "Create 16 non-admin users (saved to #{VCAP_BVT_CONFIG_FILE})"
  task :create do
    RakeHelper.prepare_all(16)
  end
end

namespace :orgs do
  desc "Delete yeti-like organizations"
  task :delete do
    exec "./scripts/yeti-hunter.rb"
  end
end

namespace :config do
  desc "Clear current BVT config file"
  task :clear_bvt do
    require 'fileutils'
    puts "Removing #{VCAP_BVT_CONFIG_FILE}"
    FileUtils.rm_rf(VCAP_BVT_CONFIG_FILE)
  end
end

TESTS_PATH = File.join(Dir.pwd, "assets")
VCAP_BVT_ASSETS_PACKAGES_HOME = File.join(File.dirname(__FILE__), ".assets-binaries")

TESTS_TO_BUILD = [
  "#{TESTS_PATH}/java_web/app_with_startup_delay",
  "#{TESTS_PATH}/java_web/java_tiny_app",
  "#{TESTS_PATH}/java_web/tomcat-version-check-app",

  "#{TESTS_PATH}/spring/spring_imagemagick"
]

desc "Build java test apps"
task :build_test_apps do
  `mvn -v 2>&1`
  error_message = "\nBVT need java development environment to build java-base apps.\n"+
    "Please run 'sudo aptitude install maven2 default-jdk' on your Linux box"
  raise error_message if $?.exitstatus != 0

  ENV['MAVEN_OPTS'] = "-XX:MaxPermSize=256M"

  TESTS_TO_BUILD.each do |test|
    puts "\tBuilding '#{test}'"
    Dir.chdir test do
      sh('mvn clean package -DskipTests') do |success, _|
        if success
          binaryname = File.join("target", "*.{war,zip}")
          binary_file = Dir.glob(binaryname).first
          app_name = test.split('/')[-1]
          file_type = '.' + binary_file.split('.')[-1]
          file_name = app_name + file_type
          target_file = File.join(VCAP_BVT_ASSETS_PACKAGES_HOME, file_name)

          FileUtils.mkdir_p VCAP_BVT_ASSETS_PACKAGES_HOME
          FileUtils.cp binary_file, target_file
        else
          sh("mvn clean -q")
          fail "\tFailed to build #{test} - aborting build"
        end
      end
    end
    puts "\tCompleted building '#{test}'"
  end
end