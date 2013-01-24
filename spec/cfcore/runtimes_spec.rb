require 'cfcore/cfcore_helper'

describe 'core runtimes', :cfcore => true, :mcf => true do

  before(:all) do
    @session = BVT::Harness::CFSession.new
    pending "not supported in v2 yet" if @session.v2?
  end

  subject { @session.system_runtimes }

  it { should have_runtime 'java', '1.6' }
  it { should have_runtime 'java7', '1.7' }

  it { should have_runtime 'node', '0.4' }
  it { should have_runtime 'node06', '0.6' }
  it { should have_runtime 'node08', '0.8' }

  it { should have_runtime 'ruby18', '1.8.7' }
  it { should have_runtime 'ruby19', '1.9.2' }

end
