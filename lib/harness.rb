require "vcap/logging"
require "yaml"

module BVT
  module Harness
    if ENV['VCAP_BVT_HOME']
      VCAP_BVT_HOME       = ENV['VCAP_BVT_HOME']
    else
      VCAP_BVT_HOME       = File.join(ENV['HOME'], '.bvt')
    end

    VCAP_BVT_CONFIG_FILE  = File.join(VCAP_BVT_HOME, "config.yml")
    VCAP_BVT_PROFILE_FILE = File.join(VCAP_BVT_HOME, "profile.yml")
    VCAP_BVT_ERROR_LOG    = File.join(VCAP_BVT_HOME, "error.log")

    VCAP_BVT_APP_CONFIG   = File.join(File.dirname(__FILE__), "../config/assets.yml")
    VCAP_BVT_APP_ASSETS   = YAML.load_file(VCAP_BVT_APP_CONFIG)

    # setup logger
    VCAP_BVT_LOG_FILE     = File.join(VCAP_BVT_HOME, "bvt.log")
    LOGGER_LEVEL          = :debug
    config = {:level => LOGGER_LEVEL, :file => VCAP_BVT_LOG_FILE}
    Dir.mkdir(VCAP_BVT_HOME) unless Dir.exist?(VCAP_BVT_HOME)
    VCAP::Logging.setup_from_config(config)

    # Assets Data Store Config
    VCAP_BVT_ASSETS_DATASTORE_CONFIG  =  File.join(VCAP_BVT_HOME, "datastore.yml")
    VCAP_BVT_ASSETS_PACKAGES_HOME     =  File.join(File.dirname(__FILE__),
                                                   "../.assets-binaries")
    VCAP_BVT_ASSETS_PACKAGES_MANIFEST =  File.join(VCAP_BVT_ASSETS_PACKAGES_HOME,
                                                   "packages.yml")
    VCAP_BVT_ASSETS_STORE_URL         =  "http://blobs-next.cloudfoundry.com"

    ## parallel
    VCAP_BVT_PARALLEL_MAX_USERS  = 16
    VCAP_BVT_PARALLEL_SYNC_FILE  = File.join(VCAP_BVT_HOME, "sync.yml")
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
require "harness/parallelrunner"
require "harness/parallel_helper"
