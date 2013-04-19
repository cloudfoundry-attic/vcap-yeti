require "harness"
require "spec_helper"
require "harness/rake_helper"
require "verification/services"

include BVT::Spec
include BVT::Harness::RakeHelper
include BVT::Verification::Services

describe "Marketplace gateway Service" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  let(:service_from_appdirect) { 'sendgrid' }
  let(:provider_from_appdirect) { 'sendgrid' }

  it "allows user to see services from the marketplace gateway" do
    all_services = @session.system_services
    all_services.keys.should include(service_from_appdirect)
    appdirect_service = all_services.
      fetch(service_from_appdirect).
      fetch(provider_from_appdirect)
    appdirect_service.fetch(:description).should be
    appdirect_service.fetch(:plans).should be
  end
end
