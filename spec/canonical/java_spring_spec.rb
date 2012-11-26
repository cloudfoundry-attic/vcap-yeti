require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::CanonicalHelper

describe BVT::Spec::Canonical::JavaSpring do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "spring test deploy app", :p1 => true do
    app = create_push_app("app_spring_service")
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

  it "spring test mysql service", :mysql => true, :p1 => true do
    app = create_push_app("app_spring_service")
    bind_service_and_verify(app, MYSQL_MANIFEST)
  end

  it "spring test redis service", :redis => true, :p1 => true do
    app = create_push_app("app_spring_service")
    bind_service_and_verify(app, REDIS_MANIFEST)
  end

  it "spring test mongodb service", :mongodb => true, :p1 => true do
    app = create_push_app("app_spring_service")
    bind_service_and_verify(app, MONGODB_MANIFEST)
  end

  it "spring test rabbitmq service", :rabbitmq => true, :p1 => true do
    app = create_push_app("app_spring_service")
    bind_service_and_verify(app, RABBITMQ_MANIFEST)
  end

  it "spring test postgresql service", :postgresql => true do
    app = create_push_app("app_spring_service")
    bind_service_and_verify(app, POSTGRESQL_MANIFEST)
  end

  it "deploy spring 3.1 app", :redis => true do
    app = create_push_app("spring-env-app")

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

    redis_service = bind_service(REDIS_MANIFEST, app)
    type = app.get_response(:get, "/properties/sources/property/cloud."+
                                  "services.#{redis_service.name}.type").body_str
    type.should satisfy {|arg| arg.start_with? 'redis'}
    plan = app.get_response(:get, "/properties/sources/property/cloud."+
                                  "services.#{redis_service.name}.plan").body_str
    requested_plan = ENV['VCAP_BVT_SERVICE_PLAN'] || REDIS_MANIFEST[:plan] || 'free' # lib/harness/service.rb#L67-73
    plan.should == requested_plan
    password = app.get_response(:get, "/properties/sources/property/cloud.services"+
                             ".#{redis_service.name}.connection.password").body_str
    aliased_password = app.get_response(:get, "/properties/sources/property/cloud."+
                                     "services.redis.connection.password").body_str
    aliased_password.should == password
  end

  it "java test deploy app using java 6" do
    app = create_push_app("app_spring_service")

    runtime = app.manifest['runtime']
    version = VCAP_BVT_SYSTEM_RUNTIMES[runtime][:version]

    contents = app.get_response(:get, '/java')
    contents.should_not == nil
    contents.body_str.should_not == nil
    contents.body_str.should =~ /#{version}/
    contents.response_code.should == 200
    contents.close

  end

end

