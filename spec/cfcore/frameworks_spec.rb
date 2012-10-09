require 'cfcore/cfcore_helper'

describe 'core frameworks', :cfcore => true, :mcf => true do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  subject { @session.system_frameworks }

  it { should have_framework :node, 'node', '0.4.12' }
  it { should have_framework :node, 'node06', '0.6.8' }
  it { should have_framework :node, 'node08', '0.8.2' }

  it { should have_framework :standalone, 'java', '1.6' }
  it { should have_framework :standalone, 'java7', '1.7' }

  it { should have_framework :standalone, 'ruby18', '1.8.7' }
  it { should have_framework :standalone, 'ruby19', '1.9.2p180' }
  it { should have_framework :standalone, 'node', '0.4.12' }
  it { should have_framework :standalone, 'node06', '0.6.8' }
  it { should have_framework :standalone, 'node08', '0.8.2' }

  it { should have_framework :lift, 'java', '1.6' }
  it { should have_framework :lift, 'java7', '1.7' }

  it { should have_framework :java_web, 'java', '1.6' }
  it { should have_framework :java_web, 'java7', '1.7' }

  it { should have_framework :spring, 'java', '1.6' }
  it { should have_framework :spring, 'java7', '1.7' }

  it { should have_framework :grails, 'java', '1.6' }
  it { should have_framework :grails, 'java7', '1.7' }

  it { should have_framework :sinatra, 'ruby18', '1.8.7' }
  it { should have_framework :sinatra, 'ruby19', '1.9.2p180' }

  it { should have_framework :rails3, 'ruby18', '1.8.7' }
  it { should have_framework :rails3, 'ruby19', '1.9.2p180' }

  it { should have_framework :play, 'java', '1.6' }
  it { should have_framework :play, 'java7', '1.7' }

  it { should have_framework :rack, 'ruby18', '1.8.7' }
  it { should have_framework :rack, 'ruby19', '1.9.2p180' }

end
