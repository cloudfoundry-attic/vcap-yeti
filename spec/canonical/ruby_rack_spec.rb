require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::CanonicalHelper

describe "Canonical::RubyRack" do

  before(:all) { @session = BVT::Harness::CFSession.new }

  after do
    show_crashlogs
    @session.cleanup!
  end

  it "rack test deploy app", :p1 => true do
    app = create_push_app("app_rack_service")
    app.get_response(:get).to_str.should == "hello from sinatra"
    app.get_response(:get, "/crash").to_str.should =~ /502 Bad Gateway/
  end

  it "rack test setting RACK_ENV" do
    app = create_push_app("app_rack_service")
    add_env(app,'RACK_ENV','development')
    app.stop
    app.start

    app.get_response(:get,"/rack/env").code.should == 200
    app.get_response(:get,"/rack/env").to_str.should == 'development'
  end

  it "rack test mysql service", :mysql => true, :p1 => true do
    app = create_push_app("app_rack_service", nil, nil, [MYSQL_MANIFEST])
    verify_keys(app, MYSQL_MANIFEST)
  end

  it "rack test redis service", :redis => true do
    app = create_push_app("app_rack_service", nil, nil, [REDIS_MANIFEST])
    verify_keys(app, REDIS_MANIFEST)
  end

  it "rack test mongodb service", :mongodb => true do
    app = create_push_app("app_rack_service", nil, nil, [MONGODB_MANIFEST])
    verify_keys(app, MONGODB_MANIFEST)
  end

  it "rack test rabbitmq service", :rabbitmq => true do
    app = create_push_app("app_rack_service", nil, nil, [RABBITMQ_MANIFEST])
    verify_keys(app, RABBITMQ_MANIFEST)
  end

  it "rack test postgresql service", :postgresql => true do
    app = create_push_app("app_rack_service", nil, nil, [POSTGRESQL_MANIFEST])
    verify_keys(app, POSTGRESQL_MANIFEST)
  end
end
