require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::AutoStagingHelper

describe BVT::Spec::AutoStaging::Node06Node do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Node.js version 0.6 autostaging", :mysql=>true, :redis=>true,
    :mongodb=>true, :rabbitmq=>true, :postgresql=>true do
    app = push_app_and_verify("node_autoconfig06", "/", "hello from node")

    manifests = [MYSQL_MANIFEST,
                 REDIS_MANIFEST,
                 MONGODB_MANIFEST,
                 RABBITMQ_MANIFEST,
                 POSTGRESQL_MANIFEST]
    manifests.each do |service_manifest|
      bind_service(service_manifest, app)
      verify_service_autostaging(service_manifest, app)
    end
  end

end
