require 'cfcore/cfcore_helper'

describe 'core services', :cfcore => true, :mcf => true do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  subject { @session.system_services }

  it { should have_service 'mysql', '5.5' }

  it { should have_service 'postgresql', '9.1' }

  it { should have_service 'redis', '2.6' }

  it { should have_service 'rabbitmq', '2.8' }

  it { should have_service 'mongodb', '2.2' }

end
