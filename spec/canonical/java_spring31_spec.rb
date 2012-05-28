require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Canonical::JavaSpring31 do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "deploy spring 3.1 app", :spring => true do
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

