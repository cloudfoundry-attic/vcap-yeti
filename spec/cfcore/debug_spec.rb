require 'cfcore/cfcore_helper'

describe 'debug mode', :cfcore => true, :mcf => true do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  it 'should not allow debugging on cloudfoundry.com' do
    info = @session.info

    if @session.TARGET == 'cloudfoundry.com'
      info[:allow_debug].should be_false
    end
  end

end
