require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Harness::HTTP_RESPONSE_CODE

describe "ServiceRebinding" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    show_crashlogs
    @session.cleanup!
  end

  VCAP_BVT_MYSQL_OBJS      = {:table      => "foobar_table",
                              :function   => "foobar_function",
                              :procedure  => "foobar_procedure"}
  VCAP_BVT_POSTGRESQL_OBJS = {:table      => "foobar_table",
                              :function   => "foobar_function",
                              :sequence  => "foobar_sequence"}

  def get_db_objs(service_manifest)
    objs = case service_manifest[:vendor]
             when 'mysql'       then   VCAP_BVT_MYSQL_OBJS
             when 'postgresql'  then   VCAP_BVT_POSTGRESQL_OBJS
             else
           end
  end

  def create_db_obj(service_manifest, app)
    get_db_objs(service_manifest).each do |k, v|
      res = app.get_response(:put, "/service/#{service_manifest[:vendor]}" +
                                   "/#{k}/#{v}", "")
      res.code.should == OK
    end
  end

  def drop_db_obj(service_manifest, app)
    get_db_objs(service_manifest).each do |k, v|
      res = app.get_response(:delete, "/service/#{service_manifest[:vendor]}" +
                                      "/#{k}/#{v}")
      res.code.should == OK
    end
  end

  def verify_service(service_manifest, app, key)
    data = "#{service_manifest[:vendor]}#{key}"
    url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
    app.get_response(:post, "/service/#{url}/#{key}", data)
    app.get_response(:get, "/service/#{url}/#{key}").to_str.should == data
  end

  def post_data(key, data, service_manifest, app)
    url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
    app.get_response(:post, "/service/#{url}/#{key}", data)
  end

  def get_data(key, data, service_manifest, app)
    url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
    res = app.get_response(:get, "/service/#{url}/#{key}")
    res.code.should == OK
    res.to_str.should == data
  end

  def rebind(service_manifest, app)
    # provision service
    service = bind_service(service_manifest, app)

    # post data
    key = "abc"
    data = "#{service_manifest[:vendor]}#{key}"
    post_data(key, data, service_manifest, app)

    create_db_obj(service_manifest, app)

    app.unbind(service, false)
    app.bind(service)

    # Get data
    get_data(key, data, service_manifest, app)

    key = "def"
    verify_service(service_manifest, app, key)
    drop_db_obj(service_manifest, app)
  end

  def bind_apps(service_manifest, app1, app2)
    # provision service
    service = bind_service(service_manifest, app1)

    # post data
    key = "abc"
    data = "#{service_manifest[:vendor]}#{key}"
    post_data(key, data, service_manifest, app1)

    create_db_obj(service_manifest, app1)

    app2.bind(service)
    # Get data
    get_data(key, data, service_manifest, app2)
    drop_db_obj(service_manifest, app2)
  end

  it "Verify rebinding for mysql", :slow => true, :mysql => true, :p1 => true do
    app1 = create_push_app("app_sinatra_service")
    rebind(MYSQL_MANIFEST, app1)
  end

  it "Verify rebinding for postgresql", :slow => true, :postgresql => true do
    app1 = create_push_app("app_sinatra_service")
    rebind(POSTGRESQL_MANIFEST, app1)
  end

  it "Verify binding mysql to two applications", :slow => true, :mysql => true do
    app1 = create_push_app("app_sinatra_service")
    app2 = create_push_app("app_sinatra_service2")
    bind_apps(MYSQL_MANIFEST, app1, app2)
  end

  it "Verify binding postgresql to two applications", :slow => true, :postgresql => true do
    app1 = create_push_app("app_sinatra_service")
    app2 = create_push_app("app_sinatra_service2")
    bind_apps(POSTGRESQL_MANIFEST, app1, app2)
  end
end
