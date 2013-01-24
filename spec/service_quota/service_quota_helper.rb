require "harness"

module BVT::Spec
  module ServiceQuotaHelper

    SERVICE_QUOTA_CONFIG = ENV['VCAP_BVT_DEPLOY_MANIFEST'] || File.join(File.dirname(__FILE__), "service_quota.yml")
    SERVICE_CONFIG = YAML.load_file(SERVICE_QUOTA_CONFIG)
    default_service_plan = (@session && @session.v2?) ? "100" : "free"
    SERVICE_PLAN = ENV['VCAP_BVT_SERVICE_PLAN'] || default_service_plan
    SERVICE_QUOTA = {}
    SERVICE_LIST=[]

    SERVICE_CONFIG['properties']['service_plans'].each do |service,configure|
      SERVICE_LIST << service
      SERVICE_QUOTA[service] = configure[SERVICE_PLAN]["configuration"] if configure[SERVICE_PLAN]
    end

  end
end
