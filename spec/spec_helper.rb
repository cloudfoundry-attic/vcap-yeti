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
    SERVICE_URL_MAPPING = {
      "mysql"      => "mysql",
      "redis"      => "redis",
      "mongodb"    => "mongo",
      "rabbitmq"   => "rabbitmq",
      "postgresql" => "postgresql",
      "neo4j"      => "neo4j",
      "blob"       => "blob",
    }.freeze

    SERVICE_URL_MAPPING_UNSUPPORTED_VERSION = {
      "mysql"      => "mysql",
      "redis"      => "redis",
      "mongodb"    => "mongo",
      "rabbitmq"   => "amqp",
      "postgresql" => "postgres",
    }.freeze
  end
end

RSpec.configure do |config|
  include BVT::Harness::ColorHelpers

  config.before(:suite) do
    target = BVT::Harness::RakeHelper.get_target
    target_without_http = target.split('//')[-1]

    BVT::Harness::RakeHelper.get_config
    BVT::Harness::RakeHelper.set_up_parallel_user
    profile_file = File.join(BVT::Harness::VCAP_BVT_HOME, "profile.#{target_without_http}.yml")

    unless File.exists?(profile_file)
      BVT::Harness::RakeHelper.get_user
      BVT::Harness::RakeHelper.get_user_passwd
      user = BVT::Harness::RakeHelper.get_config['user']
      BVT::Harness::RakeHelper.generate_profile(user)
    end

    $vcap_bvt_profile_file ||= profile_file
    profile = YAML.load_file($vcap_bvt_profile_file)
    BVT::Harness::VCAP_BVT_SYSTEM_SERVICES = profile[:services]
  end

  config.before(:each) do
    @current_app = nil
  end

  config.include BVT::Harness::ScriptsHelper
end
