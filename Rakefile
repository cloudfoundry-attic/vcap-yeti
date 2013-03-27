$:.unshift(File.join(File.dirname(__FILE__), "lib"))
require "rspec/core/rake_task"
require "harness"
include BVT::Harness

desc "Prepare for running parallel specs"
task :prepare => ["assets:sync", "create_users"]

desc "Create 16 non-admin users (saved to ~/.bvt/config)"
task :create_users do
  RakeHelper.prepare_all(16)
end

desc "Delete yeti-like organizations"
task :delete_orgs do
  exec "./tools/scripts/yeti-hunter.rb"
end

namespace :assets do
  desc "Sync yeti assets binaries"
  task :sync do
    require "harness/assets"
    BVT::Harness::Assets.new.sync
  end
end
