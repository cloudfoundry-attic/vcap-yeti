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

  config.tty = true # allow Jenkins to color output

  config.before(:suite) do
    BVT::Harness::RakeHelper.get_config
    BVT::Harness::RakeHelper.set_up_parallel_user # sets YETI_PARALLEL_USER and YETI_PARALLEL_PASSWD to correspond with the parallel user for this parallel index
    profile_file = BVT::Harness::RakeHelper.profile_file

    unless File.exists?(profile_file)
      BVT::Harness::RakeHelper.get_user
      BVT::Harness::RakeHelper.get_user_passwd
      user = BVT::Harness::RakeHelper.get_config['user']
      BVT::Harness::RakeHelper.generate_profile(user, profile_file)
    end

    YAML.load_file(profile_file) # make sure YAML.dump works
  end

  config.before(:each) do
    @current_app = nil
  end

  config.include BVT::Harness::ScriptsHelper
end
