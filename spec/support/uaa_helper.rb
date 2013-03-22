class UaaHelper
  include Singleton

  attr_writer :uaabase, :loginbase, :username, :password

  def initialize
    @admin_client = ENV['VCAP_BVT_ADMIN_CLIENT'] || "admin"
    @admin_secret = ENV['VCAP_BVT_ADMIN_SECRET'] || "adminsecret"
    puts "** Using admin client: '#{@admin_client}' (set environment variables" +
             " VCAP_BVT_ADMIN_CLIENT / VCAP_BVT_ADMIN_SECRET to override) **"
    @username = "dev@cloudfoundry.org"
    @password = "dev"
  end

  def webclient

    return @webclient if @webclient

    begin
      token = client_token(@admin_client, @admin_secret)
    rescue RestClient::Unauthorized
      #raise RuntimeError, "Unauthorized admin client (check your config or env vars)"
    end
    return nil unless token

    client_id = "testapp"
    begin
      client = get_client(client_id, token).clone
      client["client_id"].should_not == nil
      if client["scope"].nil? || client["scope"].empty? || client["scope"]==["uaa.none"] then
        client["scope"] = ["openid", "cloud_controller.read"]
        update_client(client, token)
      end
      @webclient = {:client_id=>client["client_id"]}
    rescue RestClient::ResourceNotFound
      @webclient = register_client({:client_id=>client_id,
                                    :client_secret=>"appsecret", :authorized_grant_types=>
              ["authorization_code"], :scope=>["openid", "cloud_controller.read"]}, token)
    rescue RestClient::Unauthorized
      raise RuntimeError, "Unauthorized admin client not able to create new client"
    end

    @webclient

  end

  def client_token(client_id, client_secret)
    url = @loginbase + "/oauth/token"
    response = RestClient.post url, {:client_id=>client_id,
                                     :grant_type=>"client_credentials"}, {"Accept"=>"application/json",
                                                                          "Authorization"=>basic_auth(client_id, client_secret)}
    response.should_not == nil
    response.code.should == 200
    JSON.parse(response.body)["access_token"]
  end

  def login
    url = @loginbase + "/login.do"
    response = RestClient.post url, {:username=>@username, :password=>@password},
        {"Accept"=>"application/json"} { |response, request, result| response }
    response.should_not == nil
    response.code.should == 302
    response.headers
  end

  def get_client(client_id, token)
    url = @uaabase + "/oauth/clients/#{client_id}"
    response = RestClient.get url, {"Authorization"=>
                                        "Bearer #{token}", "Accept"=>"application/json"}
    JSON.parse(response.body)
  end

  def register_client(client, token)
    url = @uaabase + "/oauth/clients"
    response = RestClient.post url, client.to_json, {"Authorization"=>
                                                         "Bearer #{token}", "Content-Type"=>"application/json"}
    response.should_not == nil
    (response.code/100).should == 2
    client
  end

  def update_client(client, token)
    url = @uaabase + "/oauth/clients/" + client["client_id"]
    response = RestClient.put url, client.to_json, {"Authorization"=>"Bearer #{token}", "Content-Type"=>"application/json"}
    (response.code/100).should == 2
    client
  end

  def basic_auth(id, secret)
    "Basic " + Base64::strict_encode64("#{id}:#{secret}")
  end

  def get_url(path,headers={})
    url = @loginbase + path
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