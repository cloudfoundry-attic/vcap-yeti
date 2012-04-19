
module BVT
  module Harness
    VCAP_BVT_HOME = File.join(ENV['HOME'], '.bvt')
    VCAP_BVT_CONFIG_FILE = File.join(VCAP_BVT_HOME, "config.yml")
    VCAP_BVT_PROFILE_FILE = File.join(VCAP_BVT_HOME, "profile.yml")
    VCAP_BVT_LOG_FILE = File.join(VCAP_BVT_HOME, "bvt.log")
    LOGGER_LEVEL = :debug
    VCAP_BVT_APP_CONFIG = File.join(File.dirname(__FILE__), "../config/assets.yml")
  end
end

require "harness/color_helper"
require "harness/rake_helper"
require "harness/cfsession"
require "harness/app"
require "harness/service"
require "harness/user"
