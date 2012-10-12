require "harness"
require "spec_helper"
require "json"

describe BVT::Spec::Canonical::Ruby19Sinatra do
  include BVT::Spec::CanonicalHelper, BVT::Spec, BVT::Harness

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

  it "sinatra test setting RACK_ENV" do
    app = create_push_app("app_sinatra_service")
    add_env(app,'RACK_ENV','development')
    app.stop
    app.start
    app.get_response(:get,'/rack/env').body_str.should == "development"

    logs = app.logs
    logs.should include "development"
  end

  it "sinatra test mysql service", :mysql => true do
    app = create_push_app("app_sinatra_service")
    bind_service_and_verify(app, MYSQL_MANIFEST)
  end

  it "sinatra test redis service", :redis => true, :p1 => true do
    app = create_push_app("app_sinatra_service")
    bind_service_and_verify(app, REDIS_MANIFEST)
  end

  it "sinatra test mongodb service", :mongodb => true, :p1 => true do
    app = create_push_app("app_sinatra_service")
    bind_service_and_verify(app, MONGODB_MANIFEST)
  end

  it "sinatra test rabbitmq service", :rabbitmq => true, :p1 => true do
    app = create_push_app("app_sinatra_service")
    bind_service_and_verify(app, RABBITMQ_MANIFEST)
  end

  it "sinatra test postgresql service", :postgresql => true do
    app = create_push_app("app_sinatra_service")
    bind_service_and_verify(app, POSTGRESQL_MANIFEST)
  end

  it "sinatra test neo4j service", :neo4j => true, :p1 => true do
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

  it "sinatra test blob service", :blob => true, :p1 => true do
    blob_service = create_service(BLOB_MANIFEST)
    app = create_push_app("blob_app")
    app.bind(blob_service)

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

  it "memcached services", :p1 => true, :memcached => true do
    memcached_service = create_service(MEMCACHED_MANIFEST)
    app = create_push_app("memcached_app")
    app.bind(memcached_service.name)

    r1 = app.get_response(:post,"/storeincache",{:key => 'foo', :value => 'bar'}.to_json)
    r1.response_code.should == 200
    r1.close

    r2 = app.get_response(:get,"/getfromcache/foo")
    r2.should_not == nil
    r2.response_code.should == 200
    contents = JSON.parse r2.body_str
    contents["requested_key"].should == "foo"
    contents["value"].should == "bar"
    r2.close
  end

  it "sinatra test couchdb service", :couchdb => true, :p1 => true do
    app = create_push_app("couchdb_app")
    service = bind_service(COUCHDB_MANIFEST, app)

    data = { :key => 'foo', :value => 'bar'}
    res = app.get_response(:post, "/storeincouchdb", data.to_json)
    res.response_code.should == HTTP_RESPONSE_CODE::OK

    res = app.get_response(:get, "/getfromcouchdb/#{data[:key]}")
    res.response_code.should == HTTP_RESPONSE_CODE::OK
    contents = JSON.parse(res.body_str)
    contents["requested_key"].should == data[:key]
    contents["value"].should == data[:value]
  end

  it "sinatra test elasticsearch service", :elasticsearch => true, :p1 => true do
    app = create_push_app("elasticsearch_app")
    service = bind_service(ELASTICSSEARCH_MANIFEST, app)

    data = "id=foo&message=bar"
    res = app.get_response(:post, "/es/save", data)
    res.response_code.should == HTTP_RESPONSE_CODE::OK
    res.body_str.should include('"ok":true')

    res = app.get_response(:get, "/es/get/foo")
    res.response_code.should == HTTP_RESPONSE_CODE::OK
    res.body_str.should include('"exists":true')
  end
end
