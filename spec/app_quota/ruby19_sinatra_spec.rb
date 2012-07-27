require "harness"
require "spec_helper"
require "rest_client"
require "pp"

include BVT::Spec
include BVT::Harness::AppQuotaHelper

describe BVT::Spec::AppQuota::Ruby19Sinatra do
  # 20%
  VCAP_APP_QUOTA_TOLERANCE = 0.2

  # 2GB
  VCAP_INSTANCE_HARDDISK_LIMIT = 2 * 1024

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    #@session.cleanup!
  end

  it "application quota on ram limit" do
    app = create_push_app("app_quota_app")
    ram_size = detect_hardware_limit(app, :mem, 100)/1024
    offset_percentage = ram_size/app.manifest["memory"]
    # should be_within 80% ~ 120%
    offset_percentage.should be_within(VCAP_APP_QUOTA_TOLERANCE).of(1)
  end

  it "application quota on hard disk limit" do
    app = create_push_app("app_quota_app")
    disk_size = detect_hardware_limit(app, :disk, 1000000)/1024
    offset_percentage = disk_size/VCAP_INSTANCE_HARDDISK_LIMIT
    # should be_within 80% ~ 120%
    offset_percentage.should be_within(VCAP_APP_QUOTA_TOLERANCE).of(1)
  end

end
