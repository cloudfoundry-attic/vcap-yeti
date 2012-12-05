require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::UsersManagement::ACL do

  before(:all) do
    @session = BVT::Harness::CFSession.new
    SERVICE_MANIFEST_LIST = [MYSQL_MANIFEST, REDIS_MANIFEST, POSTGRESQL_MANIFEST,
        MONGODB_MANIFEST, RABBITMQ_MANIFEST, BLOB_MANIFEST]
    if ENV['VCAP_BVT_DEPLOY_MANIFEST']
      DEPLOY_MANIFEST = YAML.load_file(ENV['VCAP_BVT_DEPLOY_MANIFEST'])['properties']
    end
  end

  before(:each) do
    unless ENV['VCAP_BVT_DEPLOY_MANIFEST']
      pending "can't get your deploy manifest via env VCAP_BVT_DEPLOY_MANIFEST"
    end
  end

  after(:each) do
    @session.cleanup!
  end

  def verify_service_plan_acl
    SERVICE_MANIFEST_LIST.each do |manifest|
      service_name = manifest[:vendor]
      service_gateway = manifest[:vendor].gsub('rabbitmq',
                        'rabbit').gsub('blob', 'vblob') + "_gateway"
      acls = DEPLOY_MANIFEST[service_gateway]['acls']
      if acls && acls['plans']
        acls['plans'].each do |plan,plan_acls|
          acl_users = []
          acl_wildcards = []
          acl_users = plan_acls['users'] if plan_acls['users']
          acl_wildcards = plan_acls['wildcards'] if plan_acls['wildcards']
          ENV['VCAP_BVT_SERVICE_PLAN'] = plan
          e1 = nil
          begin
            service = @session.service(service_name, true)
            service.create(manifest)
          rescue => e
            e1 = e.to_s
          end
          if email_match(acl_users, acl_wildcards, @session.email)
            e1.should == nil
          else
            e1.should match(/(404: entity not found or inaccessible|is not available on target)/)
          end
        end
      end
    end
  end

  def verify_service_visibility
    sys_services = @session.system_services
    SERVICE_MANIFEST_LIST.each do |manifest|
      service_name = manifest[:vendor]
      service_jason = sys_services[service_name]
      service_gateway = manifest[:vendor].gsub('rabbitmq',
                        'rabbit').gsub('blob', 'vblob') + "_gateway"
      acls = DEPLOY_MANIFEST[service_gateway]['acls']
      if acls
        acl_users = []
        acl_wildcards = []
        acl_users = acls['users'] if acls['users']
        acl_wildcards = acls['wildcards'] if acls['wildcards']
        if email_match(acl_users, acl_wildcards, @session.email)
          service_jason.should_not == nil
        else
          service_jason.should == nil
        end
      end
    end
  end

  def email_match(acl_users, acl_wildcards, user_email)
    acl_users.each do |user|
      if user_email == user
        return true
      end
    end
    acl_wildcards.each do |wildcard|
      if user_email.match(/.#{wildcard}$/)
        return true
      end
    end
    return true if acl_users == [] && acl_wildcards == []
    return false
  end

  it "service plan acl" do
    verify_service_plan_acl
  end

  it "service visibility" do
    verify_service_visibility
  end

end
