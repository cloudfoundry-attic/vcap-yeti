require "harness"
require "spec_helper"
include BVT::Spec::AutoStagingHelper
include BVT::Spec

describe BVT::Spec::AutoStaging::RubyRails3 do

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def verify_rails_db_app(app, relative_path)
    response = app.get_response(:get, relative_path)
    response.should_not == nil
    response.response_code.should == BVT::Harness::HTTP_RESPONSE_CODE::OK
    p = JSON.parse(response.body_str)
    p['operation'].should == 'success'
  end

  it "start application and write data" do
    app = create_app("rails3_app")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"
    widget_name = "somewidget"
    app.get_response(:get, "/make_widget/#{widget_name}").body_str.should == \
      "Saved #{widget_name}"
  end

  it "start and test a rails db app with Gemfile that includes mysql2 gem",
    :mysql => true do
    service_manifest = MYSQL_MANIFEST
    service = create_service(MYSQL_MANIFEST)

    app = create_app("dbrails_app")
    app.push([service])
    app.healthy?.should be_true, "Application #{app.name} is not running"

    urls = %W(/db/init /db/query /db/update /db/create)
    urls.each { |url| verify_rails_db_app(app, url)}
  end

  it "rails db app with Gemfile that DOES NOT include mysql2 or sqllite gems",
    :mysql => true do
    service_manifest = MYSQL_MANIFEST
    service = create_service(MYSQL_MANIFEST)

    app = create_app("dbrails_broken_app")
    app.push([service], nil, false)
    health = app.healthy?
    health.should be_false
  end

  it "Rails autostaging", :mysql => true, :redis => true, :mongodb => true,
    :rabbitmq => true, :postgresql => true, :p1 => true do
    # provision service
    service_manifests = [MYSQL_MANIFEST, REDIS_MANIFEST, MONGODB_MANIFEST]
    services = []
    service_manifests.each { |manifest| services << create_service(manifest) }

    app = create_app("app_rails_service_autoconfig")
    app.push(services)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from rails"

    service_manifests.each {|manifest| verify_service_autostaging(manifest, app)}
    services = @session.services
    services.each {|service| app.unbind(service) if service.name =~ /t.*-mysql$/ }

    service_manifests = [RABBITMQ_MANIFEST, POSTGRESQL_MANIFEST]
    service_manifests.each do |service_manifest|
      bind_service(service_manifest, app)
      verify_service_autostaging(service_manifest, app)
    end
  end

  it "Rails opt-out of autostaging via config file", :mysql => true, :redis => true do
    # provision service
    service_manifests = [MYSQL_MANIFEST, REDIS_MANIFEST]
    services = []
    service_manifests.each { |manifest| services << create_service(manifest) }

    app = create_app("rails_autoconfig_disabled_by_file")
    app.push(services)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from rails"

    key = "connection"
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    app.get_response(:get, "/service/redis/#{key}").body_str.should == data
  end

  it "Rails opt-out of autokstaging via cf-runtime gem", :mysql => true,
    :redis => true do
    # provision service
    service_manifests = [MYSQL_MANIFEST, REDIS_MANIFEST]
    services = []
    service_manifests.each { |manifest| services << create_service(manifest) }

    app = create_app("rails_autoconfig_disabled_by_gem")
    app.push(services)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from rails"

    key = "connection"
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    app.get_response(:get, "/service/redis/#{key}").body_str.should == data
  end
end
