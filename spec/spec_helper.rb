require "harness"

module BVT
  module Spec

    module UsersManagement
      class AdminUser; end
    end

    module AutoStaging
      class Ruby18Rack; end

      class Ruby19Sinatra; end
      class Ruby19Rack; end
      class Ruby19Rails3; end

      class JavaSpring; end
    end

    module Canonical
      class JavaSpring; end
      class JavaSpring31; end
      class Ruby19Sinatra; end
      class Ruby18Rack; end
      class NodeNode; end
      class JavaStandalone; end
      class Ruby19Rails3; end
    end

    module ServiceQuota
      class Ruby19Sinatra; end
    end

    module Simple
      class JavaWeb; end
      class Ruby19Sinatra; end
      class NodeNode; end
      class Node06Node; end
      class Ruby18Rails3; end
      class Ruby19Rails3; end
    end

    MYSQL_MANIFEST      = {"vendor"=>"mysql", "version"=>"5.1"}
    REDIS_MANIFEST      = {"vendor"=>"redis", "version"=>"2.2"}
    MONGODB_MANIFEST    = {"vendor"=>"mongodb", "version"=>"1.8"}
    RABBITMQ_MANIFEST   = {"vendor"=>"rabbitmq", "version"=>"2.4"}
    POSTGRESQL_MANIFEST = {"vendor"=>"postgresql", "version"=>"9.0"}

    SERVICE_URL_MAPPING = Hash["mysql" => "mysql",
                               "redis" => "redis",
                               "mongodb" => "mongo",
                               "rabbitmq" => "rabbitmq",
                               "postgresql" => "postgresql"]

    SERVICE_URL_MAPPING_UNSUPPORTED_VERSION = Hash["mysql" => "mysql",
                                                   "redis" => "redis",
                                                   "mongodb" => "mongo",
                                                   "rabbitmq" => "amqp",
                                                   "postgresql" => "postgres"]
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    profile = YAML.load_file(BVT::Harness::VCAP_BVT_PROFILE_FILE)
    BVT::Harness::VCAP_BVT_SYSTEM_FRAMEWORKS  =  profile[:frameworks]
    BVT::Harness::VCAP_BVT_SYSTEM_RUNTIMES    =  profile[:runtimes]
    BVT::Harness::VCAP_BVT_SYSTEM_SERVICES    =  profile[:services]
  end
  config.include BVT::Harness::ScriptsHelper
end

require "autostaging/autostaging_helper"
require "canonical/canonical_helper"
