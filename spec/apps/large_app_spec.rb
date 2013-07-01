require "harness"
require "spec_helper"
require "securerandom"
include BVT::Spec

describe "Large Applications" do
  before(:all) { @session = BVT::Harness::CFSession.new }

  describe "app with a big file saved in the resource pool" do
    with_app "large_file", :debug => "sometimes"

    it 'should retrieve the file from the resource pool correctly' do
      Integer(app.get_response(:get, '/').body).should > 64000
    end
  end
end
