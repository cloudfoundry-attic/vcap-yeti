require "harness"
require "spec_helper"
include BVT::Spec::CanonicalHelper
include BVT::Spec

describe "Canonical::Node" do

  before(:all) { @session = BVT::Harness::CFSession.new }

  after do
    show_crashlogs
    @session.cleanup!
  end

  it "node test deploy app" do
    app = create_push_app("app_node_service")
    app.get_response(:get).to_str.should == "hello from node"
    app.get_response(:get, "/crash").to_str.should =~ /502 Bad Gateway/
  end

  it "node test mysql service", :mysql => true, :p1 => true do
    app = create_push_app("app_node_service", nil, nil, [MYSQL_MANIFEST])
    verify_keys(app, MYSQL_MANIFEST)
  end

  it "node test redis service", :redis => true, :p1 => true do
    app = create_push_app("app_node_service", nil, nil, [REDIS_MANIFEST])
    verify_keys(app, REDIS_MANIFEST)
  end

  it "node test mongodb service", :mongodb => true, :p1 => true do
    app = create_push_app("app_node_service", nil, nil, [MONGODB_MANIFEST])
    verify_keys(app, MONGODB_MANIFEST)
  end

  it "node test rabbitmq service", :rabbitmq => true, :p1 => true do
    app = create_push_app("app_node_service", nil, nil, [RABBITMQ_MANIFEST])
    verify_keys(app, RABBITMQ_MANIFEST)
  end

  it "node test postgresql service", :postgresql => true, :p1 => true do
    app = create_push_app("app_node_service", nil, nil, [POSTGRESQL_MANIFEST])
    verify_keys(app, POSTGRESQL_MANIFEST)
  end
end
