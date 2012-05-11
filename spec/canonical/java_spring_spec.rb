require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Canonical::JavaSpring do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "spring test deploy app", :spring => true do
    app = @session.app("app_spring_service")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.body_str.should_not == nil
    contents.body_str.should == "hello from spring"
    contents.close

    contents = app.get_response(:get, '/crash')
    contents.should_not == nil
    contents.response_code.should >= 500
    contents.response_code.should < 600
    contents.close
  end

  it "spring test mysql service", :spring => true, :mysql => true do
    app = @session.app("app_spring_service")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"

    # provision service
    service_manifest = MYSQL_MANIFEST
    bind_service(service_manifest, app)
    verify_service(service_manifest, app, 'abc')
  end

  it "spring test redis service", :spring => true, :redis => true do
    app = @session.app("app_spring_service")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"

    # provision service
    service_manifest = REDIS_MANIFEST
    bind_service(service_manifest, app)
    verify_service(service_manifest, app, 'abc')
  end

  it "spring test mongodb service", :spring => true, :mongodb => true do
    app = @session.app("app_spring_service")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"

    # provision service
    service_manifest = MONGODB_MANIFEST
    bind_service(service_manifest, app)
    verify_service(service_manifest, app, 'abc')
  end

  it "spring test rabbitmq service", :spring => true, :rabbitmq => true do
    app = @session.app("app_spring_service")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"

    # provision service
    service_manifest = RABBITMQ_MANIFEST
    bind_service(service_manifest, app)
    verify_service(service_manifest, app, 'abc')
  end

  it "spring test postgresql service", :spring => true, :postgresql => true do
    app = @session.app("app_spring_service")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"

    # provision service
    service_manifest = POSTGRESQL_MANIFEST
    bind_service(service_manifest, app)
    verify_service(service_manifest, app, 'abc')
  end

  it "deploy spring 3.1 app", :spring => true do
    app = @session.app("spring-env-app")
    app.push
    app.healthy?.should be_true, "Application #{app.name} is not running"

    response = app.get_response(:get, "/profiles/active/cloud").body_str
    response.should == 'true'

    response = app.get_response(:get, "/profiles/active/default").body_str
    response.should == 'false'

    response = app.get_response(:get, "/properties/sources/source/cloud").body_str
    response.length.should_not == 0

    app_name = app.get_response(:get, "/properties/sources/property/cloud"+
                                      ".application.name").body_str
    app_name.should == app.name
    provider_url = app.get_response(:get, "/properties/sources/property/cloud"+
                                          ".provider.url").body_str
    provider_url.should == @session.TARGET.gsub('http://api.', '')

    service_manifest = REDIS_MANIFEST
    redis_service = @session.service(service_manifest['vendor'])
    redis_service.create(service_manifest)
    app.bind(redis_service.name)

    type = app.get_response(:get, "/properties/sources/property/cloud."+
                                  "services.#{redis_service.name}.type").body_str
    type.should satisfy {|arg| arg.start_with? 'redis'}
    plan = app.get_response(:get, "/properties/sources/property/cloud."+
                                  "services.#{redis_service.name}.plan").body_str
    plan.should == 'free'
    password = app.get_response(:get, "/properties/sources/property/cloud.services"+
                             ".#{redis_service.name}.connection.password").body_str
    aliased_password = app.get_response(:get, "/properties/sources/property/cloud."+
                                     "services.redis.connection.password").body_str
    aliased_password.should == password
  end

end

