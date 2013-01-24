require "harness"
require "spec_helper"
require "json"
include BVT::Spec::CanonicalHelper
include BVT::Spec
include BVT::Harness

describe BVT::Spec::Canonical::RubySinatra do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "sinatra test deploy app" do
    app = create_push_app("app_sinatra_service")
    app.get_response(:get).to_str.should == "hello from sinatra"
    app.get_response(:get, "/crash").to_str.should =~ /502 Bad Gateway/
  end

  it "sinatra test modular app" do
    app = create_push_app("app_sinatra_modular")
    app.get_response(:get).to_str.should == "hello from sinatra"
    app.get_response(:get,'/module').to_str.should == "hello from module"
  end

  it "sinatra test setting RACK_ENV" do
    app = create_push_app("app_sinatra_service")
    add_env(app,'RACK_ENV','development')
    app.stop
    app.start
    app.get_response(:get,'/rack/env').to_str.should == "development"

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
    r.code.should == 200
    question_id = r.to_str.split(/\//).last

    r2 = app.get_response(:get, "/question/#{question_id}")
    r2.should_not == nil
    r2.code.should == 200
    contents = JSON.parse r2.to_str
    contents["question"].should == "Q1"
    contents["answer"].should == "A1"
  end

  it "sinatra test blob service", :blob => true, :p1 => true do
    blob_service = create_service(BLOB_MANIFEST)
    app = create_push_app("blob_app")
    app.bind(blob_service)

    r = app.get_response(:post, '/service/vblob/container1', 'dummy')
    r.code.should == 200

    r2 = app.get_response(:post, '/service/vblob/container1/file1', 'abc')
    r2.code.should == 200

    r3 = app.get_response(:get, '/service/vblob/container1/file1')
    r3.should_not == nil
    r3.code.should == 200
    r3.to_str.should == 'abc'
  end

  it "memcached services", :p1 => true, :memcached => true do
    memcached_service = create_service(MEMCACHED_MANIFEST)
    app = create_push_app("memcached_app")
    app.bind(memcached_service)

    r1 = app.get_response(:post,"/storeincache",{:key => 'foo', :value => 'bar'}.to_json)
    r1.code.should == 200

    r2 = app.get_response(:get,"/getfromcache/foo")
    r2.should_not == nil
    r2.code.should == 200
    contents = JSON.parse r2.to_str
    contents["requested_key"].should == "foo"
    contents["value"].should == "bar"
  end

  it "sinatra test couchdb service", :couchdb => true, :p1 => true do
    app = create_push_app("couchdb_app")
    service = bind_service(COUCHDB_MANIFEST, app)

    data = { :key => 'foo', :value => 'bar'}
    res = app.get_response(:post, "/storeincouchdb", data.to_json)
    res.code.should == HTTP_RESPONSE_CODE::OK

    res = app.get_response(:get, "/getfromcouchdb/#{data[:key]}")
    res.code.should == HTTP_RESPONSE_CODE::OK
    contents = JSON.parse(res.to_str)
    contents["requested_key"].should == data[:key]
    contents["value"].should == data[:value]
  end

  it "sinatra test elasticsearch service", :elasticsearch => true, :p1 => true do
    app = create_push_app("elasticsearch_app")
    service = bind_service(ELASTICSSEARCH_MANIFEST, app)

    data = "id=foo&message=bar"
    res = app.get_response(:post, "/es/save", data)
    res.code.should == HTTP_RESPONSE_CODE::OK
    res.to_str.should include('"ok":true')

    res = app.get_response(:get, "/es/get/foo")
    res.code.should == HTTP_RESPONSE_CODE::OK
    res.to_str.should include('"exists":true')
  end

  it "sinatra test oauth2 service", :oauth2 => true do
    app = create_push_app("oauth2_app")
    service = bind_service(OAUTH2_MANIFEST, app)
    res = app.get_response(:get, "/auth/cloudfoundry")
    res.code.should == HTTP_RESPONSE_CODE::FOUND
    res.header_str.should match "Location: http.*://(login|uaa).*"
  end

end
