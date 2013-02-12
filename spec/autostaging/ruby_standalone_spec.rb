require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::AutoStagingHelper

describe BVT::Spec::AutoStaging::RubyStandalone do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "standalone ruby18 autostaging", :mysql => true, :redis => true, :mongodb => true, :postgresql => true, :rabbitmq => true do
    # provision service
    manifests = [MYSQL_MANIFEST, REDIS_MANIFEST, MONGODB_MANIFEST,
                 RABBITMQ_MANIFEST, POSTGRESQL_MANIFEST]
    app = create_push_app("standalone_ruby18_autoconfig", nil, nil, manifests)

    manifests.each do |service_manifest|
      verify_service_autostaging(service_manifest, app)
    end
  end

end
