require "harness"
require "spec_helper"
include BVT::Spec::CanonicalHelper
include BVT::Spec

describe "Canonical::RubyRails3" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "rails3 test deploy app" do
    app = create_push_app("app_rails_service", nil, nil, [MYSQL_MANIFEST])
    app.get_response(:get).to_str.should == "hello from rails"
    app.get_response(:get, "/crash").to_str.should =~ /502 Bad Gateway/
  end

  it "rails test setting RAILS_ENV" do
    app = create_push_app("app_rails_service",nil, nil, [MYSQL_MANIFEST])
    app.stop
    add_env(app, 'RAILS_ENV', 'development')
    app.start

    app.get_response(:get).to_str.should == "hello from rails"
    logs = app.logs
    logs.should include "starting in development"
  end

  it "rails3 test services", :mysql => true, :redis => true, :mongodb => true, :rabbitmq => true, :p1 => true do
    app = create_push_app("app_rails_service", nil, nil, [MYSQL_MANIFEST, REDIS_MANIFEST, MONGODB_MANIFEST, RABBITMQ_MANIFEST])
    verify_keys(app, MYSQL_MANIFEST)
    verify_keys(app, REDIS_MANIFEST)
    verify_keys(app, MONGODB_MANIFEST)
    verify_keys(app, RABBITMQ_MANIFEST)
  end

  it "rails3 test postgresql service", :postgresql => true do
    app = create_push_app("app_rails_service", nil, nil, [POSTGRESQL_MANIFEST])
    verify_keys(app, POSTGRESQL_MANIFEST)
  end
end
