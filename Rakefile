$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require "rspec/core/rake_task"
require "harness"
include BVT::Harness

desc "Prepare for running parallel specs"
task :prepare => ["users:create"]

namespace :users do
  desc "Create 16 non-admin users (saved to #{VCAP_BVT_CONFIG_FILE})"
  task :create do
    RakeHelper.prepare_all(16)
  end
end

namespace :orgs do
  desc "Delete yeti-like organizations"
  task :delete do
    exec "./tools/scripts/yeti-hunter.rb"
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
