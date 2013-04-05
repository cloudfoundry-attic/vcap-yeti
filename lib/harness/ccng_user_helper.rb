module BVT::Harness
  class CCNGUserHelper
    attr_reader :target, :admin_user

    def initialize(target, admin_user, admin_password)
      @target = target
      @admin_user = admin_user
      @admin_password = admin_password
    end

    def setup_user(email, password, org_name, space_name)
      create_user(client, email, password).tap do |user|
        org = create_org(client, user, org_name, "yeti")
        space = create_space(client, user, org, space_name)
      end
    end

    private

    def create_user(client, email, password)
      client.register(email, password)
    end

    def create_org(client, user, org_name, quota_name)
      quota = client.quota_definition_by_name(quota_name)

      client.organization.tap do |o|
        o.name = org_name
        o.users = [user]
        o.managers = [user]
        o.billing_managers = [user]
        o.auditors = [user]
        o.quota_definition = quota
        o.create!

        o.billing_enabled = true
        o.update!
      end
    end

    def create_space(client, user, org, space_name)
      client.space.tap do |s|
        s.organization = org
        s.name = space_name
        s.developers = [user]
        s.managers = [user]
        s.auditors = [user]
        s.create!
      end
    end

    def client
      @client ||= CFoundry::V2::Client.new(@target).tap do |c|
        c.trace = !!ENV["VCAP_BVT_TRACE"]
        c.login(@admin_user, @admin_password)
      end
    end
  end
end
