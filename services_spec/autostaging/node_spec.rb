require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::AutoStagingHelper

describe "AutoStaging::Node" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after do
    show_crashlogs
    @session.cleanup!
  end

  it "Node.js version 0.4 autostaging", :mysql=>true, :redis=>true, :mongodb=>true, :rabbitmq=>true, :postgresql=>true do
    pending "Fails intermitteant. TODO: unpend!"

    manifests = [MYSQL_MANIFEST,
                 REDIS_MANIFEST,
                 MONGODB_MANIFEST,
                 RABBITMQ_MANIFEST,
                 POSTGRESQL_MANIFEST]
    app = push_app_and_verify("node_autoconfig04", "/", "hello from node", manifests)

    manifests.each do |service_manifest|
      verify_service_autostaging(service_manifest, app)
    end
  end
end
