require "harness"
require "spec_helper"

describe BVT::Spec::Canonical::Ruby19Sinatra do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "sinatra test deploy app" do
    app = create_push_app("app_sinatra_service")
    app.get_response(:get).body_str.should == "hello from sinatra"
    app.get_response(:get, "/crash").body_str.should =~ /502 Bad Gateway/
  end

  it "sinatra test mysql service", :mysql => true do
    app = create_push_app("app_sinatra_service")
    bind_service_and_verify(app, MYSQL_MANIFEST)
  end

  it "sinatra test redis service", :redis => true do
    app = create_push_app("app_sinatra_service")
    bind_service_and_verify(app, REDIS_MANIFEST)
  end

  it "sinatra test mongodb service", :mongodb => true do
    app = create_push_app("app_sinatra_service")
    bind_service_and_verify(app, MONGODB_MANIFEST)
  end

  it "sinatra test rabbitmq service", :rabbitmq => true do
    app = create_push_app("app_sinatra_service")
    bind_service_and_verify(app, RABBITMQ_MANIFEST)
  end

  it "sinatra test postgresql service", :postgresql => true do
    app = create_push_app("app_sinatra_service")
    bind_service_and_verify(app, POSTGRESQL_MANIFEST)
  end

  it "sinatra test neo4j service", :neo4j => true do
    neo4j_service = create_service(NEO4J_MANIFEST)
    app = create_push_app("neo4j_app")
    app.bind(neo4j_service.name)

    r = app.get_response(:post, '/question',
        { :question => 'Q1', :answer => 'A1'}.to_json)
    r.response_code.should == 200
    question_id = r.body_str.split(/\//).last
    r.close

    r2 = app.get_response(:get, "/question/#{question_id}")
    r2.should_not == nil
    r2.response_code.should == 200
    contents = JSON.parse r2.body_str
    contents["question"].should == "Q1"
    contents["answer"].should == "A1"
    r2.close
  end

  it "sinatra test vblob service", :vblob => true do
    vblob_service = create_service(VBLOB_MANIFEST)
    app = create_push_app("vblob_app")
    app.bind(vblob_service.name)

    r = app.get_response(:post, '/service/vblob/container1', 'dummy')
    r.response_code.should == 200
    r.close

    r2 = app.get_response(:post, '/service/vblob/container1/file1', 'abc')
    r2.response_code.should == 200
    r2.close

    r3 = app.get_response(:get, '/service/vblob/container1/file1')
    r3.should_not == nil
    r3.response_code.should == 200
    r3.body_str.should == 'abc'
    r3.close
  end

end
