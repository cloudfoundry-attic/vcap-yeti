require 'cfcore/cfcore_helper'

describe 'core services', :cfcore => true, :mcf => true do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  subject { @session.system_services }

  # By "agreement" we expect service versions to
  # depend on "v" version
  let(:mysql_versions) { @session.v2? ? ['5.5'] : ['5.1'] }
  let(:postgresql_versions) { @session.v2? ? ['9.1'] : ['9.0'] }
  let(:redis_versions) { @session.v2? ? ['2.6'] : ['2.2'] }
  let(:rabbitmq_versions) { @session.v2? ? ['2.8'] : ['2.4'] }
  let(:mongodb_versions) { @session.v2? ? ['2.2'] : ['2.0'] }

  it { mysql_versions.each { |v| should have_service 'mysql', v } }

  it { postgresql_versions.each { |v| should have_service 'postgresql', v } }

  it { redis_versions.each { |v| should have_service 'redis', v } }

  it { rabbitmq_versions.each { |v| should have_service 'rabbitmq', v } }

  it { mongodb_versions.each { |v| should have_service 'mongodb', v } }

end
