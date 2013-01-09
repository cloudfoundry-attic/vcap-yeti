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
    service = nil
    example.metadata.each do |k, v|
      if v == true && SERVICE_LIST.index(k.to_s)
        service = k.to_s
        break
      end
    end
    pending "service doesn't has this plan for quota testing" unless service && SERVICE_QUOTA[service]
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
    content.to_str.should == "OK"

    content = app.get_response(:post, "/service/mysql/querytime/#{max_long_query+2}")
    content.to_str.should == "query interrupted"
  end

  it "test postgresql max query time", :postgresql => true do
    app = create_push_app("service_quota_app")
    bind_service(POSTGRESQL_MANIFEST, app)

    max_long_query = SERVICE_QUOTA['postgresql']['max_long_query']
    content = app.get_response(:post, "/service/postgresql/querytime/#{max_long_query-1}")
    content.to_str.should == "OK"

    content = app.get_response(:post, "/service/postgresql/querytime/#{max_long_query+2}")
    content.to_str.should == "query interrupted"
  end

  it "test mysql max transaction time", :mysql => true do
    app = create_push_app("service_quota_app")
    bind_service(MYSQL_MANIFEST, app)

    is_kill_long_tx?("mysql")

    max_long_tx = SERVICE_QUOTA['mysql']['max_long_tx']
    content = app.get_response(:post, "/service/mysql/txtime/#{max_long_tx-1}")
    content.to_str.should == "OK"

    content = app.get_response(:post, "/service/mysql/txtime/#{max_long_tx*1.5}")
    content.to_str.should == "transaction interrupted"
  end

  it "test postgresql max transaction time", :postgresql => true do
    app = create_push_app("service_quota_app")
    bind_service(POSTGRESQL_MANIFEST, app)

    is_kill_long_tx?("postgresql")

    max_long_tx = SERVICE_QUOTA['postgresql']['max_long_tx']
    content = app.get_response(:post, "/service/postgresql/txtime/#{max_long_tx-1}")
    content.to_str.should == "OK"

    content = app.get_response(:post, "/service/postgresql/txtime/#{max_long_tx*1.5}")
    content.to_str.should == "transaction interrupted"
  end

  def is_kill_long_tx?(service_name)
    kill_long_tx = SERVICE_QUOTA[service_name]['kill_long_tx']
    if service_name == "mysql"
      pending "it will not kill long transactions" unless kill_long_tx == true
    end
    pending "max_long_tx not enabled" if SERVICE_QUOTA[service_name]['max_long_tx'] == 0
  end


  it "test mongodb quota enforcement", :mongodb => true do
    pending "mongodb free plan does not have storage quota enforcement" if SERVICE_PLAN == "free"
    app = create_push_app("service_quota_app")
    bind_service(MONGODB_MANIFEST, app)

    quota_size = SERVICE_QUOTA['mongodb']['quota_data_size']
    block = 100

    # a minor record
    response = app.get_response(:post, '/service/mongodb/collection?colname=testcolA&size=1')
    response.code.should == 200
    response.to_str.should == ""

    # fill up the quota data size
    written = 0
    while written <= quota_size
      content = app.get_response(:post, "/service/mongodb/collection?colname=testcolB&size=#{block}")
      written += block
    end
    result = app.get_response(:get, '/service/mongodb/db/storagesize')
    result.code.should == 200

    storage_size = result.to_str.to_i/1024/1024

    # Quota Exceed, proxy will drop the connection with clients
    content = app.get_response(:post, "/service/mongodb/collection?colname=testcolB&size=1")
    content.to_str.should =~ /Connection Blocked/

    # drop whole testcolB collection
    content = app.get_response(:delete, "/service/mongodb/collection?colname=testcolB")
    content.to_str.should == "DELETE OK"

    # repair will shrink disk files
    content = app.get_response(:post, "/service/mongodb/maintain")
    content.to_str.should == "REPAIR OK"

    # record in testcolA collection should still be there
    response = app.get_response(:get, '/service/mongodb/collection?colname=testcolA&index=1')
    response.to_str.should == "OK"

    # the write permission is back after the disk usage drop down
    content = app.get_response(:post, "/service/mongodb/collection?colname=testcolB&size=1")
    content.to_str.should == ""
  end

  it "deploy service quota application with postgresql service", :postgresql => true do
    pg_max_db_size = SERVICE_QUOTA['postgresql']['max_db_size']

    app = create_push_app("service_quota_app")
    bind_service(POSTGRESQL_MANIFEST, app)

    verify_max_db_size(pg_max_db_size, app, '/service/postgresql/tables/quota_table',
                       'ERROR:  permission denied for relation quota_table', ['connection not open','server closed the connection unexpectedly','terminating connection due to administrator command'])

    # can not create objects any more
    r = app.get_response(:post, '/service/postgresql/tables/test_table', '')
    r.code.should == 200
    r.to_str.should == "ERROR:  permission denied for schema public\n"
    r = app.get_response(:post, '/service/postgresql/functions/test_func', '')
    r.code.should == 200
    r.to_str.should == "ERROR:  permission denied for schema public\n"
    r = app.get_response(:post, '/service/postgresql/sequences/test_seq', '')
    r.code.should == 200
    r.to_str.should == "ERROR:  permission denied for schema public\n"

    # read data
    r = app.get_response(:get, "/service/postgresql/tables/quota_table")
    r.code.should == 200
    r.to_str.should == 'ok'

    # delete data from the table
    r = app.get_response(:delete, '/service/postgresql/tables/quota_table/data', '')
    r.code.should == 200
    sleep 2

    # can insert data again
    r = app.get_response(:post, '/service/postgresql/tables/quota_table/1', '')
    r.code.should == 200
    r.to_str.should == 'ok'

    # can create objects again
    r = app.get_response(:post, '/service/postgresql/tables/test_table', '')
    r.code.should == 200
    r.to_str.should == 'test_table'
    r = app.get_response(:post, '/service/postgresql/functions/test_func', '')
    r.code.should == 200
    r.to_str.should == 'test_func'
    r = app.get_response(:post, '/service/postgresql/sequences/test_seq', '')
    r.code.should == 200
    r.to_str.should == 'test_seq'

    # read data
    r = app.get_response(:get, "/service/postgresql/tables/quota_table")
    r.code.should == 200
    r.to_str.should == 'ok'
  end

  it "max_db_size for mysql service", :mysql => true do
    mysql_max_db_size = SERVICE_QUOTA['mysql']['max_db_size']

    app = create_push_app("service_quota_app")
    bind_service(MYSQL_MANIFEST, app)

    #when will we receive the following errors?
    #Query execution was interrupted: connection closed during a query
    #MySQL server has gone away: connection closed before a query
    #Lost connection to MySQL server during query: client side error. connection closed during a query
    verify_max_db_size(mysql_max_db_size, app, '/service/mysql/tables/quota_table',
                       'INSERT command denied to user', ['Query execution was interrupted', 'MySQL server has gone away', 'Lost connection to MySQL server during query'])


    # can not create objects any more
    r = app.get_response(:post, '/service/mysql/tables/test_table', '')
    r.code.should == 200
    r.to_str.should =~ /CREATE command denied to user/

    # read data
    r = app.get_response(:get, "/service/mysql/tables/quota_table")
    r.code.should == 200
    r.to_str.should == 'ok'

    # delete data from the table
    r = app.get_response(:delete, '/service/mysql/tables/quota_table/data', '')
    r.code.should == 200
    sleep 2

    # can insert data again
    r = app.get_response(:post, '/service/mysql/tables/quota_table/1', '')
    r.code.should == 200
    r.to_str.should == 'ok'

    # can create objects again
    r = app.get_response(:post, '/service/mysql/tables/test_table', '')
    r.code.should == 200
    r.to_str.should == 'test_table'

    # read data
    r = app.get_response(:get, "/service/mysql/tables/quota_table")
    r.code.should == 200
    r.to_str.should == 'ok'
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
    r.code.should == 200
    r.to_str.should == 'ok'
    r = app.get_response(:get, '/service/redis/memory')
    r.code.should == 200
    real_memory = r.to_str.to_f

    # Calculate the overhead
    diff = (real_memory - data_memory).ceil

    # Use binary search to try best to fill upto redis_max_memory
    used_memory = 0
    left = 0
    right = redis_max_memory.to_i
    while left <= right
      memory = (left + right) / 2
      r = app.get_response(:post, "/service/redis/set/#{memory}", "")
      r.code.should == 200
      r.to_str.should =~ /ok|command not allowed when used memory > 'maxmemory'/
      is_oom = (r.to_str != "ok")
      if is_oom
        r = app.get_response(:post, "/service/redis/clear/#{memory}", "")
        r.code.should == 200
        r.to_str.should == "ok"
        right = memory - 1
      else
        r = app.get_response(:get, '/service/redis/memory')
        r.code.should == 200
        used_memory = r.to_str.to_f
        break if (redis_max_memory * 1024 * 1024) / 1000000.0 - used_memory < diff
        left = memory + 1
      end
    end

    # Try adding 2xDIFF_THRESHOLD memory to redis. This is enough to exceed the quota
    # usage beyond redis_max_memory
    memory += 2*diff

    r = app.get_response(:post, "/service/redis/set/#{memory}", "")
    r.code.should == 200

    # Redis 2.6 return OOM, while earlier versions return ERR, so compare only with tail
    # end of the response string
    r.to_str.should =~ /command not allowed when used memory > 'maxmemory'/

    r = app.get_response(:get, "/service/redis/data")
    r.code.should == 200
    r.to_str.should == "ok"

    r = app.get_response(:post, "/service/redis/clear/5", "")
    r.code.should == 200
    r.to_str.should == "ok"

    r = app.get_response(:post, "/service/redis/set/2", "")
    r.code.should == 200
    r.to_str.should == "ok"

    r = app.get_response(:get, "/service/redis/data")
    r.code.should == 200
    r.to_str.should == "ok"
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
    # FIXME: since we can only create 20 applications in one user,
    # So if the connection quota is very large that need more 20 applications,
    # the test is pending. To fix it, we can use multiple users to create applications.
    pending "Since the dea limitation, the test is pending when connection quota is not less than #{20 * SINGLE_APP_CLIENTS_LIMIT} " if max_clients >= 20 * SINGLE_APP_CLIENTS_LIMIT

    app_list = []
    service = create_service(manifest)

    app_number = max_clients / SINGLE_APP_CLIENTS_LIMIT + 1
    if app_number > 1
      for i in 1..app_number
        app = @session.app("redis_conn_quota_app", i.to_s)
        app.push
        app.bind(service)
        app_list << app
      end

      message_list = []
      for i in 0..app_number-1
        app = app_list[i]
        r = app.get_response(:post, "/service/#{service_url}/clients/#{SINGLE_APP_CLIENTS_LIMIT}", "")
        r.code.should == 200
        message_list << r.to_str
      end

      success_number = 0
      expect_error = 0
      message_list.each {|s|
        if s == "ok"
          success_number += SINGLE_APP_CLIENTS_LIMIT
        else
          success_number += s.split('-')[0].to_i
        end
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
      r.code.should == 200
      r.to_str.should == 'ok'

      #clean up all service connection
      app.restart

      r = app.get_response(:post, "/service/#{service_url}/clients/#{max_clients+1}", "")
      r.code.should == 200
      r.to_str.should =~ /#{error_msg}/
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
    r.to_str.should == table_name
    success_size = 0

    sizes = []
    number.times { sizes << single_app_megabytes } if number > 0
    sizes << left_quota if left_quota > 0

    sizes.each do |size|
      r = app.get_response(:post, "#{service_url}/#{size}")
      if error_msg2.any? { |err| r.to_str =~ /#{err}/ }
        success_size += r.to_str.split('-')[0].to_i
        # confirm the write permission is revoked.
        r2 = app.get_response(:post, "#{service_url}/1", "")
        r2.to_str.should =~ /#{error_msg}/
        # confirm we insert enough data to trigger quota enforcement
        (success_size.to_f / max_db_size.to_f).should > data_percent
        return
      else
        r.to_str.should == "ok"
      end
      success_size += size
    end

    r = app.get_response(:post, "#{service_url}/1", "")
    r.code.should == 200
    sleep 2

    # if no data explicit expansion, we should see permisison error
    r = app.get_response(:post, "#{service_url}/1", "")
    r.code.should == 200
    r.to_str.should =~ /#{error_msg}/
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
      content.to_str.should == "ok"
      content = app.get_response(:post, "/service/vblob/bucket#{i}/#{single_app_megabytes}")
      content.to_str.should == "ok"
    end

    content = app.get_response(:post, "/service/vblob/bucket#{number}")
    content.to_str.should == "ok"
    content = app.get_response(:post, "/service/vblob/bucket#{number}/#{left_quota}")
    content.to_str.should == "ok"

    #read
    content = app.get_response(:get, "/service/vblob/bucket0")
    content.to_str.should =~ /@object_cache=\[#/
    sleep 2

    content = app.get_response(:post, "/service/vblob/bucket#{number + 1}")
    content.to_str.should == "ok"
    content = app.get_response(:post, "/service/vblob/bucket#{number + 1}/2")
    content.to_str.should == "Connection reset by peer"

    #read
    content = app.get_response(:get, "/service/vblob/bucket0")
    content.to_str.should =~ /@object_cache=\[#/

    #delete
    content = app.get_response(:delete, "/service/vblob/bucket1/5")
    sleep 2

    #read
    content = app.get_response(:get, "/service/vblob/bucket0")
    content.to_str.should =~ /@object_cache=\[#/

    content = app.get_response(:post, "/service/vblob/bucket1")
    content.to_str.should == "ok"
    content = app.get_response(:post, "/service/vblob/obj_limit/bucket1/2")
    content.to_str.should == "ok"
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
      content.to_str.should == "ok"
      content = app.get_response(:post, "/service/vblob/obj_limit/bucket#{i}/#{single_app_objs}")
      content.to_str.should == "ok"
    end

    content = app.get_response(:post, "/service/vblob/bucket#{number}")
    content.to_str.should == "ok"
    content = app.get_response(:post, "/service/vblob/obj_limit/bucket#{number}/#{left_obj}")
    content.to_str.should == "ok"

    #read
    content = app.get_response(:get, "/service/vblob/bucket0")
    content.to_str.should =~ /@object_cache=\[#/
    sleep 2

    content = app.get_response(:post, "/service/vblob/bucket#{number + 1}")
    content.to_str.should == "ok"
    content = app.get_response(:post, "/service/vblob/obj_limit/bucket#{number + 1}/2")
    content.to_str.should == "Usage will exceed the quota"

    #read
    content = app.get_response(:get, "/service/vblob/bucket0")
    content.to_str.should =~ /@object_cache=\[#/

    #delete
    content = app.get_response(:delete, "/service/vblob/bucket1/5")
    sleep 2

    #read
    content = app.get_response(:get, "/service/vblob/bucket0")
    content.to_str.should =~ /@object_cache=\[#/

    content = app.get_response(:post, "/service/vblob/bucket1")
    content.to_str.should == "ok"
    content = app.get_response(:post, "/service/vblob/obj_limit/bucket1/2")
    content.to_str.should == "ok"
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
    r.code.should == 200
    r.to_str.should match(result_reg)
    cost = result_reg.match(r.to_str)[1].to_i
    cost.should be_within(10).of(30)
  end

  # Daylimit test only for rabbitmq now
  it "daylimit for rabbit service", :rabbitmq => true do
    pending("no configuration for bandwidth rate") unless SERVICE_QUOTA['rabbit']['bandwidth_quotas'] && SERVICE_QUOTA['rabbit']['bandwidth_quotas']['time_window'] && SERVICE_QUOTA['rabbit']['bandwidth_quotas']['per_day']
    time_window = SERVICE_QUOTA['rabbit']['bandwidth_quotas']['time_window'].to_i
    per_day = SERVICE_QUOTA['rabbit']['bandwidth_quotas']['per_day'].to_f
    pending("take too much time, please set a small time_window value") unless time_window < 600
    service = create_service(RABBITMQ_MANIFEST)
    app = create_push_app("service_quota_app")
    app.bind(service)

    result_reg = /ok-([0-9]+)/
    send_size_mb = per_day * 0.1 # Set throughput size to 30 times of rate
    [{"ok" => true, "sleep" => 0, "times" => 10},
     {"ok" => false, "sleep" => time_window, "times" => 1},
     {"ok" => true, "sleep" => 0, "times" => 1},
    ].each do |v|
      v["times"].times do
        r = app.get_response(:post, "/service/rabbitmq/bandwidth/#{send_size_mb}")
        r.code.should == 200
        if v["ok"]
          r.to_str.should match(result_reg)
        else
          r.to_str.should_not match(result_reg)
        end
      end
      sleep v["sleep"] if v["sleep"] > 0
    end
  end

end
