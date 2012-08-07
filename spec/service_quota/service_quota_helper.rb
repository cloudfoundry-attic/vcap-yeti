require "harness"

module BVT::Spec
  module ServiceQuotaHelper

    SERVICE_QUOTA_CONFIG = ENV['VCAP_BVT_SERVICE_QUOTA_CONFIG'] || File.join(File.dirname(__FILE__), "service_quota.yml")
    SERVICE_CONFIG = YAML.load_file(SERVICE_QUOTA_CONFIG)
    SERVICE_PLAN = ENV['VCAP_BVT_SERVICE_PLAN'] || "free"
    SERVICE_QUOTA = {}

    SERVICE_CONFIG['properties']['service_plans'].each do |service,configure|
      plan_config = configure[SERVICE_PLAN]["configuration"]
      SERVICE_QUOTA[service]=plan_config
    end

  end
end
