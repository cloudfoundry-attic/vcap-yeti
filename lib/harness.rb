require "vcap/logging"
require "yaml"
require "yajl"
require "json"
require "rest-client"

module BVT
  module Harness
    if ENV['VCAP_BVT_HOME']
      VCAP_BVT_HOME       = ENV['VCAP_BVT_HOME']
    else
      VCAP_BVT_HOME       = File.join(ENV['HOME'], '.bvt')
    end

    VCAP_BVT_CONFIG_FILE  = ENV['VCAP_BVT_CONFIG_FILE'] || File.join(VCAP_BVT_HOME, "config.yml")

    VCAP_BVT_APP_CONFIG   = File.join(File.dirname(__FILE__), "../config/assets.yml")
    VCAP_BVT_APP_ASSETS   = YAML.load_file(VCAP_BVT_APP_CONFIG)

    VCAP_BVT_ASSETS_PACKAGES_HOME     =  File.join(File.dirname(__FILE__), "../.assets-binaries")

    ## parallel
    VCAP_BVT_PARALLEL_MAX_USERS  = 16
  end
end

require "harness/logger_helper"

require "harness/constants"
require "harness/color_helper"
require "harness/rake_helper"
require "harness/cfsession"
require "harness/app"
require "harness/service"
require "harness/user"
require "harness/http_response_code"
require "harness/scripts_helper"
require "harness/ccng_user_helper"

require "harness/console_helper"
require "harness/cfconsole_monkey_patch"
require "harness/space"
require "harness/domain"

## exception handling in rest-client
require "harness/restclient_monkey_patch"
