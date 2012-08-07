require "harness"
require "spec_helper"
require "rest_client"
include BVT::Spec
include BVT::Spec::ServiceQuotaHelper

describe BVT::Spec::ServiceQuota::Ruby19Sinatra do
  include BVT::Spec

  before(:each) do
    @session = BVT::Harness::CFSession.new
    @service_quota_pg_maxdbsize = ENV['VCAP_BVT_SERVICE_PG_MAXDBSIZE']
  end

  after(:each) do
    @session.cleanup!
  end

  it "test mysql max query time", :mysql => true do
    app = create_push_app("service_quota_app")
    bind_service(MYSQL_MANIFEST, app)

    max_long_query = SERVICE_QUOTA['mysql']['max_long_query']
    content = app.get_response(:post, "/service/mysql/querytime/#{max_long_query-1}")
    content.body_str.should == "OK"

    content = app.get_response(:post, "/service/mysql/querytime/#{max_long_query+2}")
    content.body_str.should == "query interrupted"
  end

  it "test postgresql max query time", :postgresql => true do
    app = create_push_app("service_quota_app")
    bind_service(POSTGRESQL_MANIFEST, app)

    max_long_query = SERVICE_QUOTA['postgresql']['max_long_query']
    content = app.get_response(:post, "/service/postgresql/querytime/#{max_long_query-1}")
    content.body_str.should == "OK"

    content = app.get_response(:post, "/service/postgresql/querytime/#{max_long_query+2}")
    content.body_str.should == "query interrupted"
  end

  it "test mysql max transaction time", :mysql => true do
    app = create_push_app("service_quota_app")
    bind_service(MYSQL_MANIFEST, app)

    max_long_tx = SERVICE_QUOTA['mysql']['max_long_tx']
    content = app.get_response(:post, "/service/mysql/txtime/#{max_long_tx-1}")
    content.body_str.should == "OK"

    content = app.get_response(:post, "/service/mysql/txtime/#{max_long_tx+3}")
    content.body_str.should == "transaction interrupted"
  end

  it "test postgresql max transaction time", :postgresql => true do
    app = create_push_app("service_quota_app")
    bind_service(POSTGRESQL_MANIFEST, app)

    max_long_tx = SERVICE_QUOTA['postgresql']['max_long_tx']
    content = app.get_response(:post, "/service/postgresql/txtime/#{max_long_tx-1}")
    content.body_str.should == "OK"

    content = app.get_response(:post, "/service/postgresql/txtime/#{max_long_tx+5}")
    content.body_str.should == "transaction interrupted"
  end


  it "test mongodb quotafiles", :mongodb => true do
    app = create_push_app("service_quota_app")
    bind_service(MONGODB_MANIFEST, app)

    quota_files = SERVICE_QUOTA['mongodb']['quota_files']
    quota_size = 2**(quota_files+3)

    content = app.get_response(:post, "/service/mongodb/collection?colname=testcol&size=#{quota_size}")
    result = app.get_response(:get, '/service/mongodb/db/storagesize')
    result.response_code.should == 200

    storage_size = result.body_str.to_i/1024/1024

    diff = storage_size - quota_size
    if diff > 0
      content = app.get_response(:post, "/service/mongodb/collection?colname=testcol&size=#{diff}")
    end

    response = app.get_response(:get, '/service/mongodb/collection?colname=testcol&index=1')
    response.response_code.should == 200
    response.body_str.should == "OK"

    no_result = storage_size+10
    response = app.get_response(:get, "/service/mongodb/collection?colname=testcol&index=#{no_result}")
    response.response_code.should == 200
    response.body_str.should == "index not found"

    content = app.get_response(:post, "/service/mongodb/collection?colname=testcol&size=10")
    content.body_str.should == "db disk space quota exceeded db"

    content = app.get_response(:delete, "/service/mongodb/collection?colname=testcol&size=20")
    content.body_str.should == "DELETE OK"

    response = app.get_response(:get, '/service/mongodb/collection?colname=testcol&index=1')
    response.body_str.should == "index not found"

    content = app.get_response(:post, "/service/mongodb/collection?colname=testcol&size=10")
    content.body_str.should == ""
  end

  it "deploy service quota application with postgresql service", :postgresql => true,
    :p1 => true do
    unless @service_quota_pg_maxdbsize
      case @session.TARGET
        when /\.vcap\.me$/
          # default max db size for postgresql in dev_setup is 20
          @service_quota_pg_maxdbsize = 20
        else
          # default max db size for postgresql in dev instance is 128
          @service_quota_pg_maxdbsize = 128
      end
    end

    app = create_push_app("service_quota_app")

    bind_service(POSTGRESQL_MANIFEST, app)

    # create a table
    r = app.get_response(:post, '/service/postgresql/tables/quota_table', '')
    r.response_code.should == 200
    r.body_str.should == 'quota_table'
    r.close

    # insert data under quota
    mega = @service_quota_pg_maxdbsize.to_i - 1
    r = app.get_response(:post, "/service/postgresql/tables/quota_table/#{mega}", '')
    r.response_code.should == 200
    r.body_str.should == 'ok'
    r.close

    # insert more data to be over quota
    r = app.get_response(:post, '/service/postgresql/tables/quota_table/2', '')
    r.response_code.should == 200
    r.close
    sleep 2

    # can not insert data any more
    r = app.get_response(:post, '/service/postgresql/tables/quota_table/2', '')
    r.response_code.should == 200
    r.body_str.should == "ERROR:  permission denied for relation quota_table\n"
    r.close

    # can not create objects any more
    r = app.get_response(:post, '/service/postgresql/tables/test_table', '')
    r.response_code.should == 200
    r.body_str.should == "ERROR:  permission denied for schema public\n"
    r = app.get_response(:post, '/service/postgresql/functions/test_func', '')
    r.response_code.should == 200
    r.body_str.should == "ERROR:  permission denied for schema public\n"
    r = app.get_response(:post, '/service/postgresql/sequences/test_seq', '')
    r.response_code.should == 200
    r.body_str.should == "ERROR:  permission denied for schema public\n"
    r.close

    # delete data from the table
    r = app.get_response(:delete, '/service/postgresql/tables/quota_table/data', '')
    r.response_code.should == 200
    r.close
    sleep 2

    # can insert data again
    r = app.get_response(:post, '/service/postgresql/tables/quota_table/2', '')
    r.response_code.should == 200
    r.body_str.should == 'ok'
    r.close

    # can create objects again
    r = app.get_response(:post, '/service/postgresql/tables/test_table', '')
    r.response_code.should == 200
    r.body_str.should == 'test_table'
    r = app.get_response(:post, '/service/postgresql/functions/test_func', '')
    r.response_code.should == 200
    r.body_str.should == 'test_func'
    r = app.get_response(:post, '/service/postgresql/sequences/test_seq', '')
    r.response_code.should == 200
    r.body_str.should == 'test_seq'
    r.close
  end
end
