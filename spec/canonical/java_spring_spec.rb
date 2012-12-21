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
    contents.to_str.should_not == nil
    contents.to_str.should == "hello from spring"

    contents = app.get_response(:get, '/crash')
    contents.should_not == nil
    contents.code.should >= 500
    contents.code.should < 600
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

    response = app.get_response(:get, "/profiles/active/cloud").to_str
    response.should == 'true'

    response = app.get_response(:get, "/profiles/active/default").to_str
    response.should == 'false'

    response = app.get_response(:get, "/properties/sources/source/cloud").to_str
    response.length.should_not == 0

    app_name = app.get_response(:get, "/properties/sources/property/cloud"+
                                      ".application.name").to_str
    app_name.should == app.name
    provider_url = app.get_response(:get, "/properties/sources/property/cloud"+
                                          ".provider.url").to_str
    provider_url.should == @session.TARGET.split('.', 2)[-1]

    redis_service = bind_service(REDIS_MANIFEST, app)
    type = app.get_response(:get, "/properties/sources/property/cloud."+
                                  "services.#{redis_service.name}.type").to_str
    type.should satisfy {|arg| arg.start_with? 'redis'}
    plan = app.get_response(:get, "/properties/sources/property/cloud."+
                                  "services.#{redis_service.name}.plan").to_str
    if @session.client.info[:version] > 1
      plan.should == '100'
    else
      plan.should == 'free'
    end
    password = app.get_response(:get, "/properties/sources/property/cloud.services"+
                             ".#{redis_service.name}.connection.password").to_str
    aliased_password = app.get_response(:get, "/properties/sources/property/cloud."+
                                     "services.redis.connection.password").to_str
    aliased_password.should == password
  end

  it "java test deploy app using java 6" do
    app = create_push_app("app_spring_service")

    runtime = app.manifest['runtime']
    version = VCAP_BVT_SYSTEM_RUNTIMES[runtime][:version]

    contents = app.get_response(:get, '/java')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.to_str.should =~ /#{version}/
    contents.code.should == 200

  end

end

