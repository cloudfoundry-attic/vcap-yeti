require 'cfcore/cfcore_helper'

describe 'core runtimes', :cfcore => true, :mcf => true do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  subject { @session.system_runtimes }

  it { should have_runtime 'java', 1.6 }
  it { should have_runtime 'java7', 1.7 }

  it { should have_runtime 'node', '0.4.12' }
  it { should have_runtime 'node06', '0.6.8' }
  it { should have_runtime 'node08', '0.8.2' }

  it { should have_runtime 'ruby18', '1.8.7' }
  it { should have_runtime 'ruby19', '1.9.2p180' }

end
