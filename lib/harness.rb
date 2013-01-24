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
    VCAP_BVT_ERROR_LOG    = File.join(VCAP_BVT_HOME, "error.log")

    VCAP_BVT_APP_CONFIG   = File.join(File.dirname(__FILE__), "../config/assets.yml")
    VCAP_BVT_APP_ASSETS   = YAML.load_file(VCAP_BVT_APP_CONFIG)

    VCAP_BVT_RERUN_FILE   = File.join(File.dirname(__FILE__), "../rerun.sh")

    # Assets Data Store Config
    VCAP_BVT_ASSETS_DATASTORE_CONFIG  =  File.join(VCAP_BVT_HOME, "datastore.yml")
    VCAP_BVT_ASSETS_PACKAGES_HOME     =  File.join(File.dirname(__FILE__),
                                                   "../.assets-binaries")
    VCAP_BVT_ASSETS_PACKAGES_MANIFEST =  File.join(VCAP_BVT_ASSETS_PACKAGES_HOME,
                                                   "packages.yml")
    VCAP_BVT_ASSETS_STORE_URL         =  "http://blobs.cloudfoundry.com"

    ## parallel
    VCAP_BVT_PARALLEL_MAX_USERS  = 16
    VCAP_BVT_PARALLEL_SYNC_FILE  = File.join(VCAP_BVT_HOME, "sync.yml")

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
require "harness/parallel_helper"
require "harness/ccng_user_helper"

## to arrange rails console cases in parallel
require "harness/parallel_monkey_patch"

require "harness/console_helper"
require "harness/cfconsole_monkey_patch"
## support v2
require "harness/space"
require "harness/domain"

## test ccng v1 API
require "harness/ccng-v1-test-monkey-patch" if ENV['VCAP_BVT_CCNG_V1_TEST']

## exception handling in rest-client
require "harness/restclient_monkey_patch"
