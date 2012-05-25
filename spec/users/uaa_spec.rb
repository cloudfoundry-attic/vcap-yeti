require "harness"
require "spec_helper"
require "cfoundry"
require "restclient"

class UaaHelper
  include Singleton

  attr_writer :uaabase

  def initialize
    @admin_client = "admin"
    @admin_secret = "adminsecret"
    @username = "dev@cloudfoundry.org"
    @password = "dev"
  end

  def webclient(logger)

    return @webclient if @webclient

    begin
      token = client_token(@admin_client, @admin_secret)
    rescue RestClient::Unauthorized
      logger.error("Unauthorized admin client (check your config or env vars)")
    end
    return nil unless token

    client_id = "testapp"
    begin
      response = JSON.parse(get_url "/oauth/clients/#{client_id}",
        "Authorization"=>"Bearer #{token}")
      @webclient = {:client_id=>response["client_id"]}
    rescue RestClient::ResourceNotFound
      @webclient = register_client({:client_id=>client_id,
        :client_secret=>"appsecret", :authorized_grant_types=>
        ["authorization_code"]}, token)
    rescue RestClient::Unauthorized
      puts "Unauthorized admin client not able to create new client"
    end

    @webclient

  end

  def client_token(client_id, client_secret)
    url = @uaabase + "/oauth/token"
    response = RestClient.post url, {:client_id=>client_id, :grant_type=>
      "client_credentials", :scope=>"read write password"}, {"Accept"=>
      "application/json", "Authorization"=>basic_auth(client_id, client_secret)}
    response.should_not == nil
    response.code.should == 200
    JSON.parse(response.body)["access_token"]
  end

  def login
    url = @uaabase + "/login.do"
    response = RestClient.post url, {:username=>@username, :password=>@password},
      {"Accept"=>"application/json"} { |response, request, result| response }
    response.should_not == nil
    response.code.should == 302
    response.headers
  end

  def register_client(client, token)
    url = @uaabase + "/oauth/clients"
    response = RestClient.post url, client.to_json, {"Authorization"=>
      "Bearer #{token}", "Content-Type"=>"application/json"}
    response.should_not == nil
    response.code.should == 201
    client
  end

  def basic_auth(id, secret)
    "Basic " + Base64::strict_encode64("#{id}:#{secret}")
  end

  def get_url(path,headers={})
    url = @uaabase + path
    headers[:accept] = "application/json"
    response = RestClient.get url, headers
    response.should_not == nil
    response.code.should == 200
    response.body.should_not == nil
    response.body
  end

  def get_status(path)
    url = @uaabase + path
    begin
      response = RestClient.get url, {"Accept"=>"application/json"}
      response.code
    rescue RestClient::Exception => e
      e.http_code
    end
  end

end

describe BVT::Spec::UsersManagement::UAA do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
    @uaabase = @session.info["authorization_endpoint"]
    @uaahelper = UaaHelper.instance
    @uaahelper.uaabase = @uaabase
  end

  it "get approval prompts and the content should contain correct paths" do
    headers = @uaahelper.login
    @webclient = @uaahelper.webclient(@session.log)
    pending "Client registration unsuccessful. " +
                "This case is only available on dev_setup environment." unless @webclient
    @cookie = headers[:set_cookie][0]
    headers[:location].should == "#{@uaabase}/"
    @uaahelper.get_url "/oauth/authorize?response_type=code&client_id=#{@webclient[:client_id]}" +
      "&redirect_uri=http://anywhere.com", "Cookie" => @cookie
    response = @uaahelper.get_url "/oauth/confirm_access", "Cookie" => @cookie
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

