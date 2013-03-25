require 'harness'
require 'spec_helper'
require 'json'
require 'tempfile'
require 'base64'
include BVT::Spec

describe "ServiceLifecycle" do
  include BVT::Spec::ServiceLifecycleHelper

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  let(:service_lifecycle_config) {
    ENV['VCAP_BVT_DEPLOY_MANIFEST'] || File.join(File.dirname(__FILE__), "service_lifecycle_quota.yml")
  }

  let(:service_config) {
    (YAML.load_file(service_lifecycle_config) rescue {"properties"=>{"service_plans"=>{}}})
  }

  let(:service_plan) { ENV['VCAP_BVT_SERVICE_PLAN'] || (@session.v2? ? "100" : "free") }

  let(:service_snapshot_quota) {
    service_snapshot_quota = {}
    service_config['properties']['service_plans'].each do |service,config|
      service_snapshot_quota[service] = config[service_plan]["configuration"] if config.include?(service_plan)
    end
    service_snapshot_quota
  }

  let(:default_snapshot_quota) { 5 }

  it "Take mysql snapshot and rollback to a certain snapshot", :mysql => true do
    quota = snapshot_quota('mysql')
    pending('This test requires quota > 0') unless quota > 0

    app = create_push_app('app_sinatra_service2', nil, nil, [MYSQL_MANIFEST])

    content = app.get_response(:get, '/env')
    service_id = parse_service_id(content, 'mysql')
    get_snapshots(service_id)
    post_and_verify_service(MYSQL_MANIFEST,app,'abc','mysqlabc')
    result = create_snapshot(service_id)
    snapshot_id = result["result"]["snapshot_id"]

    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot["snapshot_id"].should == snapshot_id
    snapshot["size"].should > 0
    snapshot["date"].should_not == nil

    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should_not == nil
    snapshot["size"].should > 0
    snapshot["date"].should_not == nil

    post_and_verify_service(MYSQL_MANIFEST,app,'abc','mysqlabc2')
    rollback_snapshot(service_id, snapshot_id)
    verify_service(MYSQL_MANIFEST,app,'abc','mysqlabc')

    delete_snapshot(service_id, snapshot_id)
    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot.should == nil
    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should == nil

    (1..quota).each do |i|
      create_snapshot(service_id)
    end

    result = create_snapshot(service_id)
    result.should_not == nil
    result["status"].should == "failed"
    result["result"]["snapshot_id"].should == nil
  end

  it "Import and export serialized data for mysql service", :mysql => true do
    quota = snapshot_quota('mysql')
    pending('This test requires quota > 2') unless quota > 2 # FIXME

    app = create_push_app('app_sinatra_service2', nil, nil, [MYSQL_MANIFEST])
    post_and_verify_service(MYSQL_MANIFEST,app,'abc','mysqlabc')

    content = app.get_response(:get, '/env')
    service_id = parse_service_id(content, 'mysql')
    get_snapshots(service_id)
    result = create_snapshot(service_id)
    snapshot_id = result["result"]["snapshot_id"]

    get_serialized_url(service_id, snapshot_id)

    serialized_url = create_serialized_url(service_id, snapshot_id)
    response = get_serialized_url(service_id, snapshot_id)
    response.should == serialized_url
    serialized_data = download_data(serialized_url)

    post_and_verify_service(MYSQL_MANIFEST,app,'abc','mysqlabc2')

    import_url_snapshot_id = import_service_from_url(service_id,serialized_url)
    rollback_snapshot(service_id, import_url_snapshot_id)
    verify_service(MYSQL_MANIFEST,app,'abc','mysqlabc')

    post_and_verify_service(MYSQL_MANIFEST,app,'abc','mysqlabc2')

    import_data_snapshot_id = import_service_from_data(service_id,serialized_data)
    rollback_snapshot(service_id, import_data_snapshot_id)
    verify_service(MYSQL_MANIFEST,app,'abc','mysqlabc')

    delete_snapshot(service_id, snapshot_id)
    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot.should == nil
    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should == nil

    (1..quota).each do |i|
      create_snapshot(service_id)
    end

    result = create_snapshot(service_id)
    result.should_not == nil
    result["status"].should == "failed"
    result["result"]["snapshot_id"].should == nil
  end

  it "Take redis snapshot and rollback to a certain snapshot", :redis => true do
    quota = snapshot_quota('redis')
    pending('This test requires quota > 0') unless quota > 0

    app = create_push_app('app_sinatra_service2', nil, nil, [REDIS_MANIFEST])

    content = app.get_response(:get, '/env')
    service_id = parse_service_id(content, 'redis')
    get_snapshots(service_id)
    post_and_verify_service(REDIS_MANIFEST,app,'abc','redisabc')
    result = create_snapshot(service_id)
    snapshot_id = result["result"]["snapshot_id"]

    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot["snapshot_id"].should == snapshot_id
    snapshot["size"].should > 0
    snapshot["date"].should_not == nil

    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should_not == nil
    snapshot["size"].should > 0
    snapshot["date"].should_not == nil

    post_and_verify_service(REDIS_MANIFEST,app,'abc','redisabc2')
    rollback_snapshot(service_id, snapshot_id)
    verify_service(REDIS_MANIFEST,app,'abc','redisabc')

    delete_snapshot(service_id, snapshot_id)
    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot.should == nil
    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should == nil

    (1..quota).each do |i|
      create_snapshot(service_id)
    end

    result = create_snapshot(service_id)
    result.should_not == nil
    result["status"].should == "failed"
    result["result"]["snapshot_id"].should == nil
  end

  it "Import and export serialized data for redis service", :redis => true do
    quota = snapshot_quota('redis')
    pending('This test requires quota > 2') unless quota > 2 # FIXME

    app = create_push_app('app_sinatra_service2', nil, nil, [REDIS_MANIFEST])
    post_and_verify_service(REDIS_MANIFEST,app,'abc','redisabc')

    content = app.get_response(:get, '/env')
    service_id = parse_service_id(content, 'redis')
    get_snapshots(service_id)
    result = create_snapshot(service_id)
    snapshot_id = result["result"]["snapshot_id"]

    get_serialized_url(service_id, snapshot_id)

    serialized_url = create_serialized_url(service_id, snapshot_id)
    response = get_serialized_url(service_id, snapshot_id)
    response.should == serialized_url
    serialized_data = download_data(serialized_url)

    post_and_verify_service(REDIS_MANIFEST,app,'abc','redisabc2')

    import_url_snapshot_id = import_service_from_url(service_id,serialized_url)
    rollback_snapshot(service_id, import_url_snapshot_id)
    verify_service(REDIS_MANIFEST,app,'abc','redisabc')

    post_and_verify_service(REDIS_MANIFEST,app,'abc','redisabc2')

    import_data_snapshot_id = import_service_from_data(service_id,serialized_data)
    rollback_snapshot(service_id, import_data_snapshot_id)
    verify_service(REDIS_MANIFEST,app,'abc','redisabc')

    delete_snapshot(service_id, snapshot_id)
    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot.should == nil
    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should == nil

    (1..quota).each do |i|
      create_snapshot(service_id)
    end

    result = create_snapshot(service_id)
    result.should_not == nil
    result["status"].should == "failed"
    result["result"]["snapshot_id"].should == nil
  end

  it "Take mongodb snapshot and rollback to a certain snapshot", :mongodb => true do
    quota = snapshot_quota('mongodb')
    pending('This test requires quota > 0') unless quota > 0

    app = create_push_app('app_sinatra_service2', nil, nil, [MONGODB_MANIFEST])

    content = app.get_response(:get, '/env')
    service_id = parse_service_id(content, 'mongodb')
    get_snapshots(service_id)
    post_and_verify_service(MONGODB_MANIFEST,app,'abc','mongodbabc')
    result = create_snapshot(service_id)
    snapshot_id = result["result"]["snapshot_id"]

    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot["snapshot_id"].should == snapshot_id
    snapshot["size"].should > 0
    snapshot["date"].should_not == nil

    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should_not == nil
    snapshot["size"].should > 0
    snapshot["date"].should_not == nil

    post_and_verify_service(MONGODB_MANIFEST,app,'abc','mongodbabc2')
    rollback_snapshot(service_id, snapshot_id)
    verify_service(MONGODB_MANIFEST,app,'abc','mongodbabc')

    delete_snapshot(service_id, snapshot_id)
    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot.should == nil
    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should == nil

    (1..quota).each do |i|
      create_snapshot(service_id)
    end

    result = create_snapshot(service_id)
    result.should_not == nil
    result["status"].should == "failed"
    result["result"]["snapshot_id"].should == nil
  end

  it "Import and export serialized data for mongodb service", :mongodb => true do
    quota = snapshot_quota('mongodb')
    pending('This test requires quota > 2') unless quota > 2 # FIXME

    app = create_push_app('app_sinatra_service2', nil, nil, [MONGODB_MANIFEST])
    post_and_verify_service(MONGODB_MANIFEST,app,'abc','mongodbabc')

    content = app.get_response(:get, '/env')
    service_id = parse_service_id(content, 'mongodb')
    get_snapshots(service_id)
    result = create_snapshot(service_id)
    snapshot_id = result["result"]["snapshot_id"]

    get_serialized_url(service_id, snapshot_id)

    serialized_url = create_serialized_url(service_id, snapshot_id)
    response = get_serialized_url(service_id, snapshot_id)
    response.should == serialized_url
    serialized_data = download_data(serialized_url)

    post_and_verify_service(MONGODB_MANIFEST,app,'abc','mongodbabc2')

    import_url_snapshot_id = import_service_from_url(service_id,serialized_url)
    rollback_snapshot(service_id, import_url_snapshot_id)
    verify_service(MONGODB_MANIFEST,app,'abc','mongodbabc')

    post_and_verify_service(MONGODB_MANIFEST,app,'abc','mongodbabc2')

    import_data_snapshot_id = import_service_from_data(service_id,serialized_data)
    rollback_snapshot(service_id, import_data_snapshot_id)
    verify_service(MONGODB_MANIFEST,app,'abc','mongodbabc')

    delete_snapshot(service_id, snapshot_id)
    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot.should == nil
    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should == nil

    (1..quota).each do |i|
      create_snapshot(service_id)
    end

    result = create_snapshot(service_id)
    result.should_not == nil
    result["status"].should == "failed"
    result["result"]["snapshot_id"].should == nil
  end

  it "Take postgresql snapshot and rollback to a certain snapshot", :postgresql => true do
    quota = snapshot_quota('postgresql')
    pending('This test requires quota > 0') unless quota > 0

    app = create_push_app('app_sinatra_service2', nil, nil, [POSTGRESQL_MANIFEST])

    content = app.get_response(:get, '/env')
    service_id = parse_service_id(content, 'postgresql')
    get_snapshots(service_id)
    post_and_verify_service(POSTGRESQL_MANIFEST,app,'abc','postgresqlabc')
    result = create_snapshot(service_id)
    snapshot_id = result["result"]["snapshot_id"]

    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot["snapshot_id"].should == snapshot_id
    snapshot["size"].should > 0
    snapshot["date"].should_not == nil

    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should_not == nil
    snapshot["size"].should > 0
    snapshot["date"].should_not == nil

    post_and_verify_service(POSTGRESQL_MANIFEST,app,'abc','postgresqlabc2')
    rollback_snapshot(service_id, snapshot_id)
    verify_service(POSTGRESQL_MANIFEST,app,'abc','postgresqlabc')

    delete_snapshot(service_id, snapshot_id)
    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot.should == nil
    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should == nil

    (1..quota).each do |i|
      create_snapshot(service_id)
    end

    result = create_snapshot(service_id)
    result.should_not == nil
    result["status"].should == "failed"
    result["result"]["snapshot_id"].should == nil
  end

  it "Import and export serialized data for postgresql service", :postgresql => true do
    quota = snapshot_quota('postgresql')
    pending('This test requires quota > 2') unless quota > 2 # FIXME

    app = create_push_app('app_sinatra_service2', nil, nil, [POSTGRESQL_MANIFEST])
    post_and_verify_service(POSTGRESQL_MANIFEST,app,'abc','postgresqlabc')

    content = app.get_response(:get, '/env')
    service_id = parse_service_id(content, 'postgresql')
    get_snapshots(service_id)
    result = create_snapshot(service_id)
    snapshot_id = result["result"]["snapshot_id"]

    get_serialized_url(service_id, snapshot_id)

    serialized_url = create_serialized_url(service_id, snapshot_id)
    response = get_serialized_url(service_id, snapshot_id)
    response.should == serialized_url
    serialized_data = download_data(serialized_url)

    post_and_verify_service(POSTGRESQL_MANIFEST,app,'abc','postgresqlabc2')

    import_url_snapshot_id = import_service_from_url(service_id,serialized_url)
    rollback_snapshot(service_id, import_url_snapshot_id)
    verify_service(POSTGRESQL_MANIFEST,app,'abc','postgresqlabc')

    post_and_verify_service(POSTGRESQL_MANIFEST,app,'abc','postgresqlabc2')

    import_data_snapshot_id = import_service_from_data(service_id,serialized_data)
    rollback_snapshot(service_id, import_data_snapshot_id)
    verify_service(POSTGRESQL_MANIFEST,app,'abc','postgresqlabc')

    delete_snapshot(service_id, snapshot_id)
    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot.should == nil
    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should == nil

    (1..quota).each do |i|
      create_snapshot(service_id)
    end

    result = create_snapshot(service_id)
    result.should_not == nil
    result["status"].should == "failed"
    result["result"]["snapshot_id"].should == nil
  end

  it "Take rabbit snapshot and rollback to a certain snapshot", :rabbit => true do
    quota = snapshot_quota('rabbit')
    pending('This test requires quota > 0') unless quota > 0

    app = create_push_app('app_sinatra_service2', nil, nil, [RABBITMQ_MANIFEST])

    content = app.get_response(:get, '/env')
    service_id = parse_service_id(content, 'rabbit')
    get_snapshots(service_id)
    post_and_verify_service(RABBITMQ_MANIFEST,app,'abc','rabbitabc')
    result = create_snapshot(service_id)
    snapshot_id = result["result"]["snapshot_id"]

    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot["snapshot_id"].should == snapshot_id
    snapshot["size"].should > 0
    snapshot["date"].should_not == nil

    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should_not == nil
    snapshot["size"].should > 0
    snapshot["date"].should_not == nil

    post_and_verify_service(RABBITMQ_MANIFEST,app,'abc','rabbitabc2')
    rollback_snapshot(service_id, snapshot_id)
    post_and_verify_service(RABBITMQ_MANIFEST,app,'abc','rabbitabc')

    delete_snapshot(service_id, snapshot_id)
    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot.should == nil
    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should == nil

    (1..quota).each do |i|
      create_snapshot(service_id)
    end

    result = create_snapshot(service_id)
    result.should_not == nil
    result["status"].should == "failed"
    result["result"]["snapshot_id"].should == nil
  end

  it "Take rabbit snapshot with complex configuration and rollback to a certain snapshot", :rabbit => true do
    quota = snapshot_quota('rabbit')
    pending('This test requires quota > 0') unless quota > 0
    app = create_push_app('app_sinatra_service2', nil, nil, [RABBITMQ_MANIFEST])

    content = app.get_response(:get, '/env')
    service_id = parse_service_id(content, 'rabbit')
    items = { "queues" => [["test_queue", false], ["test_durable_queue", true]],
              "exchanges" => [["test_exchange", false], ["test_durable_exchange", true]] }
    create_items_and_verify_rabbit(RABBITMQ_MANIFEST, app, items)

    result = create_snapshot(service_id)
    snapshot_id = result["result"]["snapshot_id"]

    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot["snapshot_id"].should == snapshot_id
    snapshot["size"].should > 0
    snapshot["date"].should_not == nil

    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should_not == nil
    snapshot["size"].should > 0
    snapshot["date"].should_not == nil

    clear_and_verify_rabbit(RABBITMQ_MANIFEST, app, items)
    rollback_snapshot(service_id, snapshot_id)
    included_items, excluded_items = {}, {}
    items.each do |k, v|
      included_items[k] = [v[1]]
      excluded_items[k] = [v[0]]
    end
    get_and_verify_rabbit(RABBITMQ_MANIFEST, app, included_items, excluded_items)
  end

  it "Import and export serialized data for rabbit service", :rabbit => true do
    quota = snapshot_quota('rabbit')
    pending('This test requires quota > 2') unless quota > 2 # FIXME

    app = create_push_app('app_sinatra_service2', nil, nil, [RABBITMQ_MANIFEST])
    post_and_verify_service(RABBITMQ_MANIFEST,app,'abc','rabbitabc')

    content = app.get_response(:get, '/env')
    service_id = parse_service_id(content, 'rabbit')
    get_snapshots(service_id)
    result = create_snapshot(service_id)
    snapshot_id = result["result"]["snapshot_id"]

    get_serialized_url(service_id, snapshot_id)

    serialized_url = create_serialized_url(service_id, snapshot_id)
    response = get_serialized_url(service_id, snapshot_id)
    response.should == serialized_url
    serialized_data = download_data(serialized_url)

    post_and_verify_service(RABBITMQ_MANIFEST,app,'abc','rabbitabc2')

    import_url_snapshot_id = import_service_from_url(service_id,serialized_url)
    rollback_snapshot(service_id, import_url_snapshot_id)
    verify_service(RABBITMQ_MANIFEST,app,'abc','rabbitabc')

    post_and_verify_service(RABBITMQ_MANIFEST,app,'abc','rabbitabc2')

    import_data_snapshot_id = import_service_from_data(service_id,serialized_data)
    rollback_snapshot(service_id, import_data_snapshot_id)
    verify_service(RABBITMQ_MANIFEST,app,'abc','rabbitabc')

    delete_snapshot(service_id, snapshot_id)
    snapshot = get_snapshot(service_id, snapshot_id)
    snapshot.should == nil
    snapshots = get_snapshots(service_id)
    snapshot = snapshots["snapshots"].find {|s| s["snapshot_id"] == snapshot_id}
    snapshot.should == nil

    (1..quota).each do |i|
      create_snapshot(service_id)
    end

    result = create_snapshot(service_id)
    result.should_not == nil
    result["status"].should == "failed"
    result["result"]["snapshot_id"].should == nil
  end
end
