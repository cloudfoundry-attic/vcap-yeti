require 'cfcore/cfcore_helper'

describe 'core services', :cfcore => true, :mcf => true do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  subject { @session.system_services }

  it { should have_service 'mysql', '5.1' }

  it { should have_service 'postgresql', '9.0' }

  it { should have_service 'redis', '2.2' }

  it { should have_service 'rabbitmq', '2.4' }

  it { should have_service 'mongodb', '1.8' }
  it { should have_service 'mongodb', '2.0' }

end
