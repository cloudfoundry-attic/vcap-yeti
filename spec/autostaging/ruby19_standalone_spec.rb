require "harness"
require "spec_helper"

describe BVT::Spec::AutoStaging::Ruby19Standalone do
  include BVT::Spec
  include BVT::Spec::AutoStagingHelper

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "standalone ruby19 autostaging", :mysql => true, :redis => true,
    :mongodb => true, :rabbitmq => true, :postgresql => true do
    app = create_push_app("standalone_ruby19_autoconfig")

    # provision service
    manifests = [MYSQL_MANIFEST, REDIS_MANIFEST, MONGODB_MANIFEST,
                 RABBITMQ_MANIFEST, POSTGRESQL_MANIFEST]
    manifests.each do |service_manifest|
      bind_service(service_manifest, app)
      verify_service_autostaging(service_manifest, app)
    end
  end

end
