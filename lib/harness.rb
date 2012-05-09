require "vcap/logging"
require "yaml"

module BVT
  module Harness
    VCAP_BVT_HOME         = File.join(ENV['HOME'], '.bvt')
    VCAP_BVT_CONFIG_FILE  = File.join(VCAP_BVT_HOME, "config.yml")
    VCAP_BVT_PROFILE_FILE = File.join(VCAP_BVT_HOME, "profile.yml")

    VCAP_BVT_APP_CONFIG   = File.join(File.dirname(__FILE__), "../config/assets.yml")
    VCAP_BVT_APP_ASSETS   = YAML.load_file(VCAP_BVT_APP_CONFIG)

    # setup logger
    VCAP_BVT_LOG_FILE     = File.join(VCAP_BVT_HOME, "bvt.log")
    LOGGER_LEVEL          = :debug
    config = {:level => LOGGER_LEVEL, :file => VCAP_BVT_LOG_FILE}
    Dir.mkdir(VCAP_BVT_HOME) unless Dir.exist?(VCAP_BVT_HOME)
    VCAP::Logging.setup_from_config(config)

    APP_CHECK_LIMIT = 60
  end
end

require "harness/color_helper"
require "harness/rake_helper"
require "harness/cfsession"
require "harness/app"
require "harness/service"
require "harness/user"
require "harness/http_response_code"
require "harness/scripts_helper"
