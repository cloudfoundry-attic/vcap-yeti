require "harness"
require "spec_helper"
require "cfoundry"
require "restclient"
include BVT::Spec

describe "User::UAA" do

  before(:all) do
    target_domain = BVT::Harness::RakeHelper.get_target.split(".", 2).last
    @uaabase = ENV['VCAP_BVT_UAA_BASE'] || "uaa.#{target_domain}"
    @loginbase = ENV['VCAP_BVT_LOGIN_BASE'] || @uaabase
    @uaahelper = UaaHelper.instance
    @uaahelper.uaabase = @uaabase
    @uaahelper.loginbase = @loginbase

    # get user/password from ENV || config.yml
    @session = BVT::Harness::CFSession.new
    @uaahelper.username = @session.email
    @uaahelper.password = @session.passwd
  end

  it "get approval prompts and the content should contain correct paths" do
    headers = @uaahelper.login
    @webclient = @uaahelper.webclient
    pending("Unauthorized admin client, please set VCAP_BVT_ADMIN_CLIENT/VCAP_BVT_ADMIN_SECRET" +
                " via ENV variable.") unless @webclient
    @cookie = headers[:set_cookie][0]
    headers[:location].should =~ /#{@loginbase}/
    response = @uaahelper.get_url "/oauth/authorize?response_type=code&client_id=#{@webclient[:client_id]}" +
      "&redirect_uri=http://anywhere.com", "Cookie" => @cookie
    @approval = JSON.parse(response)
    @approval["options"].should_not == nil
  end

  it "get login prompts and the content should contain prompts" do
    headers = @uaahelper.login
    @prompts = @uaahelper.get_url "/login"
    @prompts.should =~ /prompts/
  end

  it "get Users data and the response should be UNAUTHORIZED" do
    @code = @uaahelper.get_status "/Users"
    @code.should == 401
  end
end

