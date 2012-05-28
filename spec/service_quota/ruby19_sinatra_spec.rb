require "harness"
require "spec_helper"
require "rest_client"
include BVT::Spec

describe BVT::Spec::ServiceQuota::Ruby19Sinatra do
  include BVT::Spec

  before(:each) do
    @session = BVT::Harness::CFSession.new
    @service_quota_pg_maxdbsize = ENV['VCAP_BVT_SERVICE_PG_MAXDBSIZE']
  end

  after(:each) do
    @session.cleanup!
  end

  it "deploy service quota application with postgresql service", :ruby19 => true, :sinatra => true do
    unless @service_quota_pg_maxdbsize
      # default max db size for postgresql in dev instance is 128
      @service_quota_pg_maxdbsize = 128
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
