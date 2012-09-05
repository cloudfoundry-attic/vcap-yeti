require "harness"
require "spec_helper"
require "cfoundry"
require "restclient"
include BVT::Spec

class UaaHelper
  include Singleton

  attr_writer :uaabase, :username, :password

  def initialize
    @admin_client = ENV['VCAP_BVT_ADMIN_CLIENT'] || "admin"
    @admin_secret = ENV['VCAP_BVT_ADMIN_SECRET'] || "adminsecret"
    puts "** Using admin client: '#{@admin_client}' (set environment variables" +
         " VCAP_BVT_ADMIN_CLIENT / VCAP_BVT_ADMIN_SECRET to override) **"
    @username = "dev@cloudfoundry.org"
    @password = "dev"
  end

  def webclient(logger)

    return @webclient if @webclient

    begin
      logger.debug("Login as admin")
      token = client_token(@admin_client, @admin_secret)
    rescue RestClient::Unauthorized
      logger.error("Unauthorized admin client (check your config or env vars)")
    end
    return nil unless token

    client_id = "testapp"
    begin
      response = JSON.parse(get_url "/oauth/clients/#{client_id}",
        "Authorization"=>"Bearer #{token}")
      client = response.clone
      client["client_id"].should_not == nil
      @webclient = {:client_id=>client["client_id"]}
      if client["scope"].nil? || client["scope"].empty? || client["scope"]==["uaa.none"] then
        client["scope"] = ["openid", "cloud_controller.read"]
        update_client(client, token)
      end
    rescue RestClient::ResourceNotFound
      @webclient = register_client({:client_id=>client_id,
        :client_secret=>"appsecret", :authorized_grant_types=>
        ["authorization_code"], :scope=>["openid", "cloud_controller.read"]}, token)
    rescue RestClient::Unauthorized
      logger.error("Unauthorized admin client not able to create new client")
      raise RuntimeError, "Unauthorized admin client not able to create new client"
    end

    @webclient

  end

  def client_token(client_id, client_secret)
    url = @uaabase + "/oauth/token"
    response = RestClient.post url, {:client_id=>client_id, 
      :grant_type=>"client_credentials"}, {"Accept"=>"application/json",
      "Authorization"=>basic_auth(client_id, client_secret)}
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

  def update_client(client, token)
    url = @uaabase + "/oauth/clients/" + client["client_id"]
    response = RestClient.put url, client.to_json, {"Authorization"=>"Bearer #{token}", "Content-Type"=>"application/json"}
    response.code.should == 204
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

  before(:all) do
    @session = BVT::Harness::CFSession.new
    @uaabase = ENV['VCAP_BVT_UAA_BASE'] || @session.info["authorization_endpoint"]
    @uaahelper = UaaHelper.instance
    @uaahelper.uaabase = @uaabase

    # get admin user/password from ENV || config.yml
    yeti_config = YAML.load_file(BVT::Harness::VCAP_BVT_CONFIG_FILE)
    @uaahelper.username = ENV['VCAP_BVT_ADMIN_USER'] || yeti_config['admin']['email']
    @uaahelper.password = ENV['VCAP_BVT_ADMIN_USER_PASSWD'] || yeti_config['admin']['passwd']
  end

  it "get approval prompts and the content should contain correct paths",
  :admin => true, :p1 => true do
    headers = @uaahelper.login
    @webclient = @uaahelper.webclient(@session.log)
    pending("admin client is not valid, please input VCAP_BVT_ADMIN_CLIENT/VCAP_BVT_ADMIN_SECRET" +
                " via ENV variable.") unless @webclient
    @cookie = headers[:set_cookie][0]
    headers[:location].should =~ /#{@uaabase}/
    @uaahelper.get_url "/oauth/authorize?response_type=code&client_id=#{@webclient[:client_id]}" +
      "&redirect_uri=http://anywhere.com", "Cookie" => @cookie
    response = @uaahelper.get_url "/oauth/confirm_access", "Cookie" => @cookie
    @approval = JSON.parse(response)
    @approval["options"].should_not == nil
  end

  it "get login prompts and the content should contain prompts", :p1 => true, :admin => true do
    headers = @uaahelper.login
    @prompts = @uaahelper.get_url "/login"
    @prompts.should =~ /prompts/
  end

  it "get Users data and the response should be UNAUTHORIZED", :p1 => true, :admin => true do
    @code = @uaahelper.get_status "/Users"
    @code.should == 401
  end
end

