require "harness"
require "spec_helper"
require "rest_client"
include BVT::Spec
include BVT::Spec::ServiceQuotaHelper

describe BVT::Spec::ServiceQuota::RubySinatra do

  SINGLE_APP_CLIENTS_LIMIT = 200

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  before(:each) do
    if @session.TARGET =~ /\.vcap\.me$/
      pending "service quota cases are not available in dev setup env"
    end
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

    is_kill_long_tx?("mysql")

    max_long_tx = SERVICE_QUOTA['mysql']['max_long_tx']
    content = app.get_response(:post, "/service/mysql/txtime/#{max_long_tx-1}")
    content.body_str.should == "OK"

    content = app.get_response(:post, "/service/mysql/txtime/#{max_long_tx*1.5}")
    content.body_str.should == "transaction interrupted"
  end

  it "test postgresql max transaction time", :postgresql => true do
    app = create_push_app("service_quota_app")
    bind_service(POSTGRESQL_MANIFEST, app)

    is_kill_long_tx?("postgresql")

    max_long_tx = SERVICE_QUOTA['postgresql']['max_long_tx']
    content = app.get_response(:post, "/service/postgresql/txtime/#{max_long_tx-1}")
    content.body_str.should == "OK"

    content = app.get_response(:post, "/service/postgresql/txtime/#{max_long_tx*1.5}")
    content.body_str.should == "transaction interrupted"
  end

  def is_kill_long_tx?(service_name)
    kill_long_tx = SERVICE_QUOTA[service_name]['kill_long_tx']
    if service_name == "mysql"
      pending "it will not kill long transactions" unless kill_long_tx == true
    end
    pending "max_long_tx not enabled" if SERVICE_QUOTA[service_name]['max_long_tx'] == 0
  end


  it "test mongodb quotafiles", :mongodb => true do
    pending "pending until mongo proxy is ready"
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

    content = app.get_response(:post, "/service/mongodb/collection?colname=testcol&size=1")
    content.body_str.should =~ /quota exceeded/

    content = app.get_response(:delete, "/service/mongodb/collection?colname=testcol&size=2")
    content.body_str.should == "DELETE OK"

    response = app.get_response(:get, '/service/mongodb/collection?colname=testcol&index=1')
    response.body_str.should == "index not found"

    content = app.get_response(:post, "/service/mongodb/collection?colname=testcol&size=1")
    content.body_str.should == ""
  end

  it "deploy service quota application with postgresql service", :postgresql => true do
    pg_max_db_size = SERVICE_QUOTA['postgresql']['max_db_size']

    app = create_push_app("service_quota_app")
    bind_service(POSTGRESQL_MANIFEST, app)

    verify_max_db_size(pg_max_db_size, app, '/service/postgresql/tables/quota_table',
                       'ERROR:  permission denied for relation quota_table', ['connection not open','server closed the connection unexpectedly','terminating connection due to administrator command'])

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

    # read data
    r = app.get_response(:get, "/service/postgresql/tables/quota_table")
    r.response_code.should == 200
    r.body_str.should == 'ok'
    r.close

    # delete data from the table
    r = app.get_response(:delete, '/service/postgresql/tables/quota_table/data', '')
    r.response_code.should == 200
    r.close
    sleep 2

    # can insert data again
    r = app.get_response(:post, '/service/postgresql/tables/quota_table/1', '')
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

    # read data
    r = app.get_response(:get, "/service/postgresql/tables/quota_table")
    r.response_code.should == 200
    r.body_str.should == 'ok'
    r.close
  end

  it "max_db_size for mysql service", :mysql => true do
    mysql_max_db_size = SERVICE_QUOTA['mysql']['max_db_size']

    app = create_push_app("service_quota_app")
    bind_service(MYSQL_MANIFEST, app)

    verify_max_db_size(mysql_max_db_size, app, '/service/mysql/tables/quota_table',
                       'INSERT command denied to user', ['Query execution was interrupted'])


    # can not create objects any more
    r = app.get_response(:post, '/service/mysql/tables/test_table', '')
    r.response_code.should == 200
    r.body_str.should =~ /CREATE command denied to user/
    r.close

    # read data
    r = app.get_response(:get, "/service/mysql/tables/quota_table")
    r.response_code.should == 200
    r.body_str.should == 'ok'
    r.close

    # delete data from the table
    r = app.get_response(:delete, '/service/mysql/tables/quota_table/data', '')
    r.response_code.should == 200
    r.close
    sleep 2

    # can insert data again
    r = app.get_response(:post, '/service/mysql/tables/quota_table/1', '')
    r.response_code.should == 200
    r.body_str.should == 'ok'
    r.close

    # can create objects again
    r = app.get_response(:post, '/service/mysql/tables/test_table', '')
    r.response_code.should == 200
    r.body_str.should == 'test_table'
    r.close

    # read data
    r = app.get_response(:get, "/service/mysql/tables/quota_table")
    r.response_code.should == 200
    r.body_str.should == 'ok'
    r.close
  end

  it "max_memory of redis service", :redis => true do
    redis_max_memory = SERVICE_QUOTA['redis']['max_memory'].to_f

    app = create_push_app("service_quota_app")
    bind_service(REDIS_MANIFEST, app)

    # Since redis uses up more memory than the actual size of data,
    # we'll do a best fill upto redis_max_memory

    # Write 1MB data to get the memory overhead
    data_memory = 1
    r = app.get_response(:post, "/service/redis/set/#{data_memory}", "")
    r.response_code.should == 200
    r.body_str.should == 'ok'
    r.close
    r = app.get_response(:get, '/service/redis/memory')
    r.response_code.should == 200
    real_memory = r.body_str.to_f
    r.close

    # Calculate the overhead
    diff = (real_memory - data_memory).ceil

    # Use binary search to try best to fill upto redis_max_memory
    used_memory = 0
    left = 0
    right = redis_max_memory.to_i
    while left <= right
      memory = (left + right) / 2
      r = app.get_response(:post, "/service/redis/set/#{memory}", "")
      r.response_code.should == 200
      r.body_str.should =~ /ok|command not allowed when used memory > 'maxmemory'/
      is_oom = (r.body_str != "ok")
      r.close
      if is_oom
        r = app.get_response(:post, "/service/redis/clear/#{memory}", "")
        r.response_code.should == 200
        r.body_str.should == "ok"
        r.close
        right = memory - 1
      else
        r = app.get_response(:get, '/service/redis/memory')
        r.response_code.should == 200
        used_memory = r.body_str.to_f
        r.close
        break if (redis_max_memory * 1024 * 1024) / 1000000.0 - used_memory < diff
        left = memory + 1
      end
    end

    # Try adding 2xDIFF_THRESHOLD memory to redis. This is enough to exceed the quota
    # usage beyond redis_max_memory
    memory += 2*diff

    r = app.get_response(:post, "/service/redis/set/#{memory}", "")
    r.response_code.should == 200

    # Redis 2.6 return OOM, while earlier versions return ERR, so compare only with tail
    # end of the response string
    r.body_str.should =~ /command not allowed when used memory > 'maxmemory'/
    r.close

    r = app.get_response(:get, "/service/redis/data")
    r.response_code.should == 200
    r.body_str.should == "ok"
    r.close

    r = app.get_response(:post, "/service/redis/clear/5", "")
    r.response_code.should == 200
    r.body_str.should == "ok"
    r.close

    r = app.get_response(:post, "/service/redis/set/2", "")
    r.response_code.should == 200
    r.body_str.should == "ok"
    r.close

    r = app.get_response(:get, "/service/redis/data")
    r.response_code.should == 200
    r.body_str.should == "ok"
    r.close
  end

  it "max_clients of postgresql service", :postgresql => true do
    postgresql_max_clients = SERVICE_QUOTA['postgresql']['max_clients']

    verify_max_clients(postgresql_max_clients, POSTGRESQL_MANIFEST, 'postgresql',
                       'FATAL:  too many connections for database')
  end

  it "max_clients of mysql service", :mysql => true do
    mysql_max_clients = SERVICE_QUOTA['mysql']['max_clients']

    verify_max_clients(mysql_max_clients, MYSQL_MANIFEST, "mysql",
                       "has exceeded the 'max_user_connections' resource")
  end

  it "max_clients of mongodb service", :mongodb => true do
    mongodb_max_clients = SERVICE_QUOTA['mongodb']['max_clients']

    verify_max_clients(mongodb_max_clients, MONGODB_MANIFEST, 'mongodb',
                       'Operation failed with the following exception: #<Mongo::ConnectionFailure')
  end

  it "max_clients of rabbitmq service", :rabbitmq => true do
    rabbitmq_max_clients = SERVICE_QUOTA['rabbit']['max_clients']

    verify_max_clients(rabbitmq_max_clients, RABBITMQ_MANIFEST, 'rabbitmq',
                       'connection timeout')
  end

  it "max_clients of redis service", :redis => true do
    redis_max_clients = SERVICE_QUOTA['redis']['max_clients']

    verify_max_clients(redis_max_clients, REDIS_MANIFEST, 'redis',
                       'ERR max number of clients reached')
  end

  def verify_max_clients(max_clients, manifest, service_url, error_msg)
    app_list = []
    service = create_service(manifest)

    app_number = max_clients / SINGLE_APP_CLIENTS_LIMIT + 1
    if app_number > 1
      for i in 1..app_number
        app = @session.app("service_quota_app", i.to_s)
        app.push
        app.bind(service)
        app_list << app
      end

      body_str_list = []
      for i in 0..app_number-1
        app = app_list[i]
        r = app.get_response(:post, "/service/#{service_url}/clients/#{SINGLE_APP_CLIENTS_LIMIT}", "")
        r.response_code.should == 200
        body_str_list << r.body_str
        r.close
      end

      success_number = 0
      expect_error = 0
      body_str_list.each {|s|
        temp = s.split('-')[0].to_i
        temp = SINGLE_APP_CLIENTS_LIMIT if temp == 0
        success_number += temp
        if s =~ /#{error_msg}/
          expect_error += 1
        end
      }
      expect_error.should eql(1), "1 error expected, actual errors: #{expect_error}"
      success_number.should be_within(5).of(max_clients-1)
    else
      app = create_push_app("service_quota_app")
      app.bind(service)

      r = app.get_response(:post, "/service/#{service_url}/clients/#{max_clients-1}", "")
      r.response_code.should == 200
      r.body_str.should == 'ok'
      r.close

      #clean up all service connection
      app.restart

      r = app.get_response(:post, "/service/#{service_url}/clients/#{max_clients+1}", "")
      r.response_code.should == 200
      r.body_str.should =~ /#{error_msg}/
      r.close
    end
  end

  def verify_max_db_size(max_db_size, app, service_url, error_msg, error_msg2 = [])
    single_app_megabytes = 200
    table_name = service_url.split('/')[-1]
    data_percent = 0.8
    data_percent = ENV['SERVICE_QUOTA_DB_SIZE_PERCENT'] if ENV['SERVICE_QUOTA_DB_SIZE_PERCENT']
    error_msg2 << error_msg

    number = max_db_size / single_app_megabytes
    left_quota = max_db_size % single_app_megabytes - 1

    r = app.get_response(:post, service_url, "")
    r.body_str.should == table_name
    r.close
    success_size = 0

    sizes = []
    number.times { sizes << single_app_megabytes } if number > 0
    sizes << left_quota if left_quota > 0

    sizes.each do |size|
      r = app.get_response(:post, "#{service_url}/#{size}")
      if error_msg2.any? { |err| r.body_str =~ /#{err}/ }
        success_size += r.body_str.split('-')[0].to_i
        # confirm the write permission is revoked.
        r2 = app.get_response(:post, "#{service_url}/1", "")
        r2.body_str.should =~ /#{error_msg}/
        r2.close
        # confirm we insert enough data to trigger quota enforcement
        (success_size.to_f / max_db_size.to_f).should > data_percent
        return
      else
        r.body_str.should == "ok"
      end
      success_size += size
      r.close
    end

    r = app.get_response(:post, "#{service_url}/1", "")
    r.response_code.should == 200
    r.close
    sleep 2

    # if no data explicit expansion, we should see permisison error
    r = app.get_response(:post, "#{service_url}/1", "")
    r.response_code.should == 200
    r.body_str.should =~ /#{error_msg}/
    r.close
  end

  it "max_db_size of vblob service", :vblob => true do
    config = SERVICE_QUOTA['vblob']
    if config['vblobd_quota']
      # non-wardenized blob service (bytes --> MB)
      blob_disk_quota = config['vblobd_quota']/(1024*1024)
    elsif config['max_disk']
      # non-wardenized blob service (MB)
      blob_disk_quota = config['max_disk']
    else
      # non-wardenized: https://github.com/cloudfoundry/cf-release/blob/master/jobs/vblob_node/templates/vblob_node.yml.erb#L37
      # wardenized: https://github.com/cloudfoundry/cf-release/blob/warden/jobs/vblob_node_ng/templates/vblob_node.yml.erb#L46
      blob_disk_quota = 2048
    end

    app = create_push_app("service_quota_app")
    bind_service(BLOB_MANIFEST, app)

    single_app_megabytes = 200

    number = blob_disk_quota / single_app_megabytes
    left_quota = blob_disk_quota % single_app_megabytes

    for i in 0..number - 1
      content = app.get_response(:post, "/service/vblob/bucket#{i}")
      content.body_str.should == "ok"
      content.close
      content = app.get_response(:post, "/service/vblob/bucket#{i}/#{single_app_megabytes}")
      content.body_str.should == "ok"
      content.close
    end

    content = app.get_response(:post, "/service/vblob/bucket#{number}")
    content.body_str.should == "ok"
    content.close
    content = app.get_response(:post, "/service/vblob/bucket#{number}/#{left_quota}")
    content.body_str.should == "ok"
    content.close

    #read
    content = app.get_response(:get, "/service/vblob/bucket0")
    content.body_str.should =~ /@object_cache=\[#/
    content.close
    sleep 2

    content = app.get_response(:post, "/service/vblob/bucket#{number + 1}")
    content.body_str.should == "ok"
    content.close
    content = app.get_response(:post, "/service/vblob/bucket#{number + 1}/2")
    content.body_str.should == "Connection reset by peer"
    content.close

    #read
    content = app.get_response(:get, "/service/vblob/bucket0")
    content.body_str.should =~ /@object_cache=\[#/
    content.close

    #delete
    content = app.get_response(:delete, "/service/vblob/bucket1/5")
    content.close
    sleep 2

    #read
    content = app.get_response(:get, "/service/vblob/bucket0")
    content.body_str.should =~ /@object_cache=\[#/
    content.close

    content = app.get_response(:post, "/service/vblob/bucket1")
    content.body_str.should == "ok"
    content.close
    content = app.get_response(:post, "/service/vblob/obj_limit/bucket1/2")
    content.body_str.should == "ok"
    content.close
  end

  it "max_obj_limit of vblob service", :vblob => true do
    pending "it needs about 18 minutes to finish, please remove pending manually if you want to run it"
    vblob_max_obj_limit = SERVICE_QUOTA['vblob']['max_obj_limit'] || 32768 # https://github.com/cloudfoundry/cf-release/blob/warden/jobs/vblob_node/templates/vblob_node.yml.erb#L38

    app = create_push_app("service_quota_app")
    bind_service(BLOB_MANIFEST, app)

    single_app_objs = 1000

    number = vblob_max_obj_limit / single_app_objs
    left_obj = vblob_max_obj_limit % single_app_objs

    for i in 0..number-1
      content = app.get_response(:post, "/service/vblob/bucket#{i}")
      content.body_str.should == "ok"
      content.close
      content = app.get_response(:post, "/service/vblob/obj_limit/bucket#{i}/#{single_app_objs}")
      content.body_str.should == "ok"
      content.close
    end

    content = app.get_response(:post, "/service/vblob/bucket#{number}")
    content.body_str.should == "ok"
    content.close
    content = app.get_response(:post, "/service/vblob/obj_limit/bucket#{number}/#{left_obj}")
    content.body_str.should == "ok"
    content.close

    #read
    content = app.get_response(:get, "/service/vblob/bucket0")
    content.body_str.should =~ /@object_cache=\[#/
    content.close
    sleep 2

    content = app.get_response(:post, "/service/vblob/bucket#{number + 1}")
    content.body_str.should == "ok"
    content.close
    content = app.get_response(:post, "/service/vblob/obj_limit/bucket#{number + 1}/2")
    content.body_str.should == "Usage will exceed the quota"
    content.close

    #read
    content = app.get_response(:get, "/service/vblob/bucket0")
    content.body_str.should =~ /@object_cache=\[#/
    content.close

    #delete
    content = app.get_response(:delete, "/service/vblob/bucket1/5")
    content.close
    sleep 2

    #read
    content = app.get_response(:get, "/service/vblob/bucket0")
    content.body_str.should =~ /@object_cache=\[#/
    content.close

    content = app.get_response(:post, "/service/vblob/bucket1")
    content.body_str.should == "ok"
    content.close
    content = app.get_response(:post, "/service/vblob/obj_limit/bucket1/2")
    content.body_str.should == "ok"
    content.close
  end

  # Bandwidth test only for rabbitmq now
  it "bandwidth rate for rabbit service", :rabbitmq => true do
    pending("no configuration for bandwidth rate") unless SERVICE_QUOTA['rabbit']['bandwidth_quotas'] && SERVICE_QUOTA['rabbit']['bandwidth_quotas']['per_second']
    service = create_service(RABBITMQ_MANIFEST)
    app = create_push_app("service_quota_app")
    app.bind(service)

    rabbit_bandwidth_rate = SERVICE_QUOTA['rabbit']['bandwidth_quotas']['per_second'].to_f
    result_reg = /ok-([0-9]+)/
    send_size_mb = rabbit_bandwidth_rate * 30 # Set throughput size to 30 times of rate
    r = app.get_response(:post, "/service/rabbitmq/bandwidth/#{send_size_mb}")
    r.response_code.should == 200
    r.body_str.should match(result_reg)
    cost = result_reg.match(r.body_str)[1].to_i
    cost.should be_within(10).of(30)
    r.close
  end

end
