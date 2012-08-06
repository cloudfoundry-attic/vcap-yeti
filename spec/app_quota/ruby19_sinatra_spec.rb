require "harness"
require "spec_helper"

include BVT::Spec
include BVT::Harness::AppQuotaHelper
include BVT::Harness::HTTP_RESPONSE_CODE

describe BVT::Spec::AppQuota::Ruby19Sinatra do
  # 5%
  VCAP_APP_QUOTA_TOLERANCE = 0.05

  # 2GB
  VCAP_MEMORY_LIMIT = 2 * 1024
  VCAP_INSTANCE_HARDDISK_LIMIT = 2 * 1024

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "ram limit for 1 application with 1 instance" do
    app = create_push_app("app_quota_app")

    mem = app.stats[:"0"][:stats][:usage][:mem] / 1024
    app.crashes.should be_empty, "There is application #{app.name} crashes" +
        " information at beginning."

    # allocate memory with 5% tolerance
    size = app.manifest['memory'] - mem - app.manifest['memory'] * VCAP_APP_QUOTA_TOLERANCE
    app.get_response(:get, "/eat/ram?n=#{size}")
    stats = app.stats
    stats[:"0"][:stats].should_not == "DOWN"
    mem = stats[:"0"][:stats][:usage][:mem] / 1024
    app.crashes.should be_empty, "This is application #{app.name} crashes information, " +
        "after allocate #{mem}MB memory."

    # allocate memory to exceed memory limit
    app.get_response(:get, "/eat/ram?n=#{app.manifest['memory']}")

    app.crashes.should_not be_empty, "There is no expected crash information record"
    if app.stats[:"0"][:stats] == "DOWN"
      app.logs.should =~ /Memory limit of #{app.manifest['memory']}M exceeded./
    end
  end

  it "ram limit for 1 application with n instance" do
    app = create_push_app("app_quota_app")
    total_instance = VCAP_MEMORY_LIMIT / app.manifest['memory']
    memory = app.manifest['memory']
    app.scale(total_instance, memory)

    mem = app.stats[:"0"][:stats][:usage][:mem] / 1024
    app.crashes.should be_empty, "There is application #{app.name} crashes" +
        " information at beginning."

    # allocate memory with 5% tolerance
    size = app.manifest['memory'] - mem - app.manifest['memory'] * VCAP_APP_QUOTA_TOLERANCE
    origin_stats = {}
    crashes = []
    (total_instance + 1).times do
      origin_stats = app.stats
      response = app.get_response(:get, "/eat/ram?n=#{size}")
      crashes = app.crashes
      if response.response_code == GATEWAY_ERROR || !crashes.empty?
        break
      end
    end

    crashes.should_not be_empty, "There is no expected crash information record"
    diff = 0
    app.stats.each do |index, stat|
      diff += 1 if stat[:stats][:usage][:mem] != origin_stats[index][:stats][:usage][:mem]
    end
    diff.should equal(1), "There are more than one instance crashed at the moment"
  end

  it "ram limit for n application with n instance" do
    app = create_push_app("app_quota_app")
    total_instance = VCAP_MEMORY_LIMIT / app.manifest['memory']
    memory = app.manifest['memory']
    app.scale(total_instance, memory)

    mem = app.stats[:"0"][:stats][:usage][:mem] / 1024
    app.crashes.should be_empty, "There is application #{app.name} crashes" +
        " information at beginning."

    app2 = @session.app("app_quota_app", "1")
    lambda {app2.push}.should raise_error(RuntimeError,
          /Not enough memory capacity, you're allowed: #{VCAP_MEMORY_LIMIT}M/)
  end

  it "hard disk limit for 1 application with n instances" do
    app = create_push_app("app_quota_app")
    total_instance = VCAP_MEMORY_LIMIT / app.manifest['memory']
    memory = app.manifest['memory']
    app.scale(total_instance, memory)

    disk = app.stats[:"0"][:stats][:usage][:disk] / 1024.0 / 1024
    app.crashes.should be_empty, "There is application #{app.name} crashes" +
        " information at beginning."

    # allocate disk with 5% tolerance
    size = VCAP_INSTANCE_HARDDISK_LIMIT - disk - VCAP_INSTANCE_HARDDISK_LIMIT * VCAP_APP_QUOTA_TOLERANCE
    origin_stats = {}
    crashes = []
    (total_instance + 1).times do
      origin_stats = app.stats
      response = app.get_response(:get, "/eat/disk?n=#{size}")
      crashes = app.crashes
      if response.response_code == GATEWAY_ERROR || !crashes.empty?
        break
      end
    end

    crashes.should_not be_empty, "There is no expected crash information record"
    diff = 0
    app.stats.each do |index, stat|
      if stat[:state] != origin_stats[index][:state]
        diff += 1
      elsif stat[:stats][:usage][:disk] != origin_stats[index][:stats][:usage][:disk]
        diff += 1
      end
    end
    diff.should equal(1), "There are more than one instance crashed at the moment"
  end

end
