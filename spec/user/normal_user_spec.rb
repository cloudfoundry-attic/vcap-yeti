require "harness"
require "spec_helper"

describe "User::NormalUser" do

  before(:each) do
    @session = BVT::Harness::CFSession.new
    @session.token.should_not be(nil), "cannot login target environment, #{@session.TARGET}"
  end

  it "check JWT token" do
    if @session.email.end_with?("@vmware.com") || @session.email.end_with?("@rbcon.com")
      @session.token.auth_header.should match /(^bearer\s\S+[.]\S+[.]\S+$)/
    end
  end

  it "Reset user authentication token" do
    token = @session.token
    #login again
    test_session = BVT::Harness::CFSession.new
    token2 = test_session.token
    token2.should_not be(token), "Fail to get another token"
  end

end
