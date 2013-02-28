require "harness"
require "json"
require 'yaml'
require 'syck'
YAML::ENGINE.yamler = 'syck'

class Bignum
  def to_json(options = nil)
    to_s
  end
end

class Fixnum
  def to_json(options = nil)
    to_s
  end
end

module BVT
  module Spec

    module UsersManagement
      class AdminUser; end
      class NormalUser; end
      class UAA; end
      class ACL; end
    end

    module AutoStaging
      class RubyRack; end
      class RubyStandalone; end
      class RubyRails3; end
      class RubySinatra; end
      class JavaSpring; end
      class JavaGrails; end
      class NodeNode; end
    end

    module Canonical
      class JavaPlay; end
      class JavaSpring; end
      class JavaGrails; end
      class JavaLift; end
      class RubySinatra; end
      class RubyRack; end
      class NodeNode; end
      class RubyRails3; end
      class ScalaPlay; end
    end

    module ServiceQuota
      class RubySinatra; end
    end

    module ImageMagicKSupport
      class RubySinatra; end
      class NodeNode; end
      class Java; end
    end

    module ServiceLifecycle
      class RubySinatra; end
    end

    module ServiceBroker
      class RubySinatra; end
    end

    module MarketplaceGateway
      class RubySinatra; end
    end

    module ServiceRebinding
      class RubySinatra; end
    end

    module AppPerformance
      class RubySinatra; end
    end

    module AcmManager
      class Acm; end
    end
    module Simple
      class JavaJavaWeb; end
      class JavaStandalone; end
      class NodeNode; end
      class NodeStandalone; end
      class RubyStandalone; end
      class RubyRails3; end
      class RubySinatra; end

      module Info
        class RubySinatra; end
      end

      module Lifecycle
        class RubySinatra; end
      end

      module Update
        class RubySinatra; end
      end

      module RubyGems
        class RubySinatra; end
      end

      module FileRange
        class RubySinatra; end
      end

      module RailsConsole
        class Console; end
      end
    end

    module OrgSpace
      class Space; end
    end

    module CustomDomain
      class Domain; end
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
  include BVT::Harness::ColorHelpers
  config.before(:suite) do
    target = BVT::Harness::RakeHelper.get_target
    target_without_http = target.split('//')[-1]
    config = BVT::Harness::RakeHelper.get_config
    profile_file = File.join(BVT::Harness::VCAP_BVT_HOME, "profile.#{target_without_http}.yml")
    unless File.exists? profile_file
      BVT::Harness::RakeHelper.get_user
      BVT::Harness::RakeHelper.get_user_passwd
      user = BVT::Harness::RakeHelper.get_config['user']
      BVT::Harness::RakeHelper.check_environment(user)
    end
    $vcap_bvt_profile_file ||= profile_file
    profile = YAML.load_file($vcap_bvt_profile_file)
    BVT::Harness::VCAP_BVT_SYSTEM_SERVICES = profile[:services]
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