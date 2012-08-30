require "harness"
require "spec_helper"

describe BVT::Spec::AutoStaging::Ruby18Rails3 do
  include BVT::Spec::AutoStagingHelper, BVT::Spec

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Rails autostaging", :mysql => true, :redis => true, :mongodb => true,
    :rabbitmq => true, :postgresql => true, :p1 => true do
    # provision service
    service_manifests = [MYSQL_MANIFEST, REDIS_MANIFEST, MONGODB_MANIFEST]
    services = []
    service_manifests.each { |manifest| services << create_service(manifest) }

    app = create_app("app_rails_service_autoconfig18")
    app.push(services)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from rails"

    service_manifests.each {|manifest| verify_service_autostaging(manifest, app)}
    services = @session.services
    services.each {|service| app.unbind(service) if service.name =~ /t.*-mysql$/ }

    service_manifests = [RABBITMQ_MANIFEST, POSTGRESQL_MANIFEST]
    service_manifests.each do |service_manifest|
      bind_service(service_manifest, app)
      verify_service_autostaging(service_manifest, app)
    end
  end
end
