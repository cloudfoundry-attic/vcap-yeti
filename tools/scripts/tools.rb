require "vcap/logging"
require "yaml"

module Tools
  VCAP_BVT_HOME                     = File.join(ENV['HOME'], '.bvt')
  # Assets Data Store Config
  VCAP_BVT_ASSETS_DATASTORE_CONFIG  = File.join(VCAP_BVT_HOME, "datastore.yml")
  VCAP_BVT_ASSETS_PACKAGES_HOME     = File.join(File.dirname(__FILE__),
                                                "../../.assets-binaries")
  VCAP_BVT_ASSETS_PACKAGES_MANIFEST = File.join(VCAP_BVT_ASSETS_PACKAGES_HOME,
                                                "packages.yml")
  VCAP_BVT_ASSETS_STORE_URL         = "http://bolbs.cloudfoundry.com"
end

require "assets_helper"
