module BVT::Harness
  module CCNGUserHelper

    def create_user(uaa_url, uaa_cc_secret, cc_url, cc_admin_email, cc_admin_password, email, password, org_name, space_name)
      with_uaa_target(uaa_url) do
        user_guid = create_uaa_user(uaa_cc_secret, email, password)
        token = auth_token(cc_admin_email, cc_admin_password)
        quota_guid = get_paid_quota_guid(cc_url, token)
        create_cc_user(cc_url, token, user_guid)
        org_guid = create_cc_org(cc_url, token, org_name, user_guid, quota_guid)
        space_guid = create_cc_space(cc_url, token, space_name, org_guid, user_guid)
      end
    end

    def create_uaa_user(uaa_cc_secret, email, password)
      with_cc_uaa_client(uaa_cc_secret) do
        output = run "uaac user add #{email} --email #{email} --given_name yeti --family_name testuser  -p #{password}"
        error("Could not create uaa user: #{output}") unless output =~ /added/
        uaa_uid(email)
      end
    end

    def create_cc_user(cc_url, token, guid)
      auth_header = {"AUTHORIZATION" => token}
      response = RestClient.post("#{cc_url}/v2/users", {"guid" => guid}.to_json, auth_header)
      output = response.to_str
      cc_guid = output[/"guid": "([^"]*)/, 1]
      error "could not extract user guid" unless guid
      error "cc guid did not match uaa guid" unless cc_guid == guid
      guid
    end

    def get_paid_quota_guid(cc_url, token)
      auth_header = {"AUTHORIZATION" => token}
      response = RestClient.get("#{cc_url}/v2/quota_definitions", auth_header)
      output = response.to_str
      output_hash = Yajl::Parser.parse(output)
      resource = output_hash["resources"].select do |r|
        r["entity"]["name"] == "paid"
      end
      error "could not find paid quota" unless resource
      resource.first["metadata"]["guid"]
    end

    def create_cc_org(cc_url, token, name, user_guid, quota_guid)
      auth_header = {"AUTHORIZATION" => token}
      data = { "name" => name,
               "user_guids" => [user_guid],
               "manager_guids" => [user_guid],
               "quota_definition_guid" => quota_guid }
      response = RestClient.post("#{cc_url}/v2/organizations", data.to_json, auth_header)
      output = response.to_str
      guid = output[/"guid": "([^"]*)/, 1]
      error "could not extract space guid" unless guid
      RestClient.put("#{cc_url}/v2/organizations/#{guid}", {"billing_enabled" => true}.to_json, auth_header)
      guid
    end

    def create_cc_space(cc_url, token, name, org_guid, user_guid)
      auth_header = {"AUTHORIZATION" => token}
      data = { "name" => name,
               "organization_guid" => org_guid,
               "manager_guids" => [user_guid],
               "developer_guids" => [user_guid] }
      response = RestClient.post("#{cc_url}/v2/spaces", data.to_json, auth_header)
      output = response.to_str
      guid = output[/"guid": "([^"]*)/, 1]
      error "could not extract org guid" unless guid
      guid
    end

    def run(cmd)
      `#{cmd}`
    end

    def error(str)
      abort "Error: #{str}"
    end

    def with_uaa_target(uaa_url)
      output = run "uaac target"
      orig_target = output[/target set to ([^,]*)?/, 1]
      output = run "uaac target #{uaa_url}"
      error("Could not target: #{output}") unless output =~ /target set to/
      begin
        yield if block_given?
      ensure
        if orig_target
          run "uaac target #{orig_target}"
        end
      end
    end

    def with_cc_uaa_client(uaa_cc_secret)
      output = run "uaac token client get cloud_controller -s #{uaa_cc_secret}"
      error "Error while creating user: #{output}" if output =~ /error/
      begin
        yield if block_given?
      ensure
        run "uaac token delete cloud_controller"
      end
    end

    def uaa_uid(email)
      # cmdline copied from a previous bash script, hence the grep/sed
      output = run "uaac user get #{email} | grep ' id: ' | sed 's/ *id: //'"
      output.chomp
    end

    def auth_token(email, password)
      output = run "uaac token get #{email} #{password}"
      error("Could not get auth token: #{output}") if output =~ /failed/
      output = run "uaac context | grep access_token | sed 's/ *access_token: //'"
      "bearer #{output.chomp}"
    end

    extend self
  end
end
