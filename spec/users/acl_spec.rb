require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::UsersManagement::ACL do

  before(:all) do
    @session = BVT::Harness::CFSession.new
    SERVICE_MANIFEST_LIST = [MYSQL_MANIFEST, REDIS_MANIFEST, MONGODB_MANIFEST,
                             MONGODB_MANIFEST, RABBITMQ_MANIFEST]
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

  def verify_get_service_plan
    sys_services = @session.system_services
    SERVICE_MANIFEST_LIST.each do |manifest|
      service_name = manifest[:vendor]
      plans = sys_services[service_name][:plans]
      service_gateway = manifest[:vendor].gsub('rabbitmq', 'rabbit') + "_gateway"
      acls = DEPLOY_MANIFEST[service_gateway]['acls']
      if acls && acls['plans']
        acls['plans'].each do |plan,plan_acls|
          acl_wildcards = plan_acls['wildcards']
          if acl_wildcards
            acl_email = get_acl_email(acl_wildcards)
            if @session.email.match(/@(#{acl_email})\.com$/)
              plans.include?(plan).should == true
            else
              plans.include?(plan).should == false
            end
          end
        end
      end
    end
  end

  def verify_create_service
    SERVICE_MANIFEST_LIST.each do |manifest|
      service_name = manifest[:vendor]
      service_gateway = manifest[:vendor].gsub('rabbitmq', 'rabbit') + "_gateway"
      acls = DEPLOY_MANIFEST[service_gateway]['acls']
      if acls && acls['plans']
        acls['plans'].each do |plan,plan_acls|
          acl_wildcards = plan_acls['wildcards']
          acl_email = get_acl_email(acl_wildcards)
          ENV['VCAP_BVT_SERVICE_PLAN'] = plan
          service = @session.service(service_name, false)
          e1 = nil
          begin
            service.create(manifest)
          rescue => e
            e1 = e.to_s
          end
          if @session.email.match(/@(#{acl_email})\.com$/)
            e1.should == nil
          else
            e1.should =~ /404: entity not found or inaccessible/
          end
        end
      end
    end
  end

  def get_acl_email(email_list)
    str = ''
    email_list.each do |email|
      str += email.split('@')[1].gsub('.com', '') + '|'
    end
    if str.length > 1
      str = str.slice(0..-2)
    end
    str
  end

  it "acl: get service plan list" do
    pending('bug in /services/v1/offerings')
    verify_get_service_plan
  end

  it "acl: create service with a plan" do
    verify_create_service
  end

  it "acl: blob service visibility" do
    vblob_service = @session.system_services['blob']
    acls = DEPLOY_MANIFEST['vblob_gateway']['acls']
    if acls && acls['plans']
      acls['plans'].each do |plan,plan_acls|
        acl_wildcards = plan_acls['wildcards']
        if acl_wildcards
          acl_email = get_acl_email(acl_wildcards)
          if @session.email.match(/@(#{acl_email})\.com$/)
            vblob_service.should_not == nil
            vblob_service[:versions].should_not == nil
          else
            vblob_service.should == nil
          end
        end
      end
    end
  end

end
