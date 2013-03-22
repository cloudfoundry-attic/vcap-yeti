require "harness"
require "json"
require 'yaml'
require 'syck'
YAML::ENGINE.yamler = 'syck'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].map { |f| require f }

class Bignum
  def to_json(_ = nil)
    to_s
  end
end

class Fixnum
  def to_json(_ = nil)
    to_s
  end
end

module BVT
  module Spec
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

def show_crashlogs
  return unless example.exception
  logger = VCAP::Logging.logger(File.basename($0))

  if @current_app
    @current_app.logs
    @current_app.crashlogs
  else
    logger.warn("==== Spec failed, but no app detected ====")
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
    @current_app = nil
    log_case_begin_end(:begin)
  end

  config.after(:each) do
    log_case_begin_end(:end)
    show_crashlogs
  end

  config.include BVT::Harness::ScriptsHelper
end
