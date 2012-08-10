require "harness"

module BVT
  module Spec

    module UsersManagement
      class AdminUser; end
      class NormalUser; end
      class UAA; end
    end

    module AutoStaging
      class Ruby18Rack; end
      class Ruby18Standalone; end
      class Ruby19Sinatra; end
      class Ruby19Rack; end
      class Ruby19Rails3; end
      class Ruby19Standalone; end
      class JavaSpring; end
      class JavaGrails; end
    end

    module Canonical
      class JavaPlay; end
      class Java7Play; end
      class JavaSpring; end
      class Java7Spring; end
      class JavaGrails; end
      class Java7Grails; end
      class JavaLift; end
      class Ruby19Sinatra; end
      class Ruby18Rack; end
      class NodeNode; end
      class Ruby19Rails3; end
      class ScalaPlay; end
    end

    module ServiceQuota
      class Ruby19Sinatra; end
    end

    module ImageMagicKSupport
      class Ruby19Sinatra; end
      class NodeNode; end
    end

    module ServiceLifecycle
      class Ruby19Sinatra; end
    end

    module ServiceBroker
      class Ruby18Sinatra; end
    end

    module ServiceRebinding
      class Ruby19Sinatra; end
    end

    module AppPerformance
      class Ruby19Sinatra; end
    end

    module AcmManager
      class Acm; end
    end
    module Simple
      class JavaJavaWeb; end
      class JavaStandalone; end
      class Java7Standalone; end
      class NodeNode; end
      class NodeStandalone; end
      class Node06Node; end
      class Node08Node; end
      class Node06Standalone; end
      class Ruby18Rails3; end
      class Ruby18Standalone; end
      class Ruby19Rails3; end
      class Ruby19Sinatra; end
      class Ruby19Standalone; end
      class ErlangStandalone; end
      class PhpStandalone; end
      class Python2Standalone; end
      class ErlangOtpRebar; end
      class PhpPhp; end
      class Python2Wsgi; end
      class Python2Django; end

      module Info
        class Ruby19Sinatra; end
      end

      module Lifecycle
        class Ruby19Sinatra; end
      end

      module Update
        class Ruby19Sinatra; end
      end

      module RubyGems
        class Ruby19Sinatra; end
      end

      module FileRange
        class Ruby19Sinatra; end
      end

      module RailsConsole
        class Ruby18Rails3; end
        class Ruby19Rails3; end
      end
    end

    SERVICE_URL_MAPPING = Hash["mysql"      => "mysql",
                               "redis"      => "redis",
                               "mongodb"    => "mongo",
                               "rabbitmq"   => "rabbitmq",
                               "postgresql" => "postgresql",
                               "neo4j"      => "neo4j",
                               "blob"       => "blob"]

    SERVICE_URL_MAPPING_UNSUPPORTED_VERSION = Hash["mysql"      => "mysql",
                                                   "redis"      => "redis",
                                                   "mongodb"    => "mongo",
                                                   "rabbitmq"   => "amqp",
                                                   "postgresql" => "postgres"]
  end
end

def log_case_begin_end(flag)
  # add case begin/end string to log file
  logger = VCAP::Logging.logger(File.basename($0))
  metadata = example.metadata
  case flag
    when :begin
      logger.info("======= #{metadata[:example_group][:description_args]} " +
                      "#{metadata[:description_args]} begin =======")
    when :end
      logger.info("======= #{metadata[:example_group][:description_args]} " +
                      "#{metadata[:description_args]} end =======")
    else
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    BVT::Harness::VCAP_BVT_CONFIG = BVT::Harness::RakeHelper.get_config
    profile = YAML.load_file(BVT::Harness::VCAP_BVT_PROFILE_FILE)
    BVT::Harness::VCAP_BVT_SYSTEM_FRAMEWORKS  =  profile[:frameworks]
    BVT::Harness::VCAP_BVT_SYSTEM_RUNTIMES    =  profile[:runtimes]
    BVT::Harness::VCAP_BVT_SYSTEM_SERVICES    =  profile[:services]
  end

  config.before(:each) do
    log_case_begin_end(:begin)
  end

  config.after(:each) do
    log_case_begin_end(:end)
  end

  config.include BVT::Harness::ScriptsHelper
end

require "autostaging/autostaging_helper"
require "canonical/canonical_helper"
require "service_lifecycle/service_lifecycle_helper"
