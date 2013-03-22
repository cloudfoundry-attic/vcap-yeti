require "harness"
require "spec_helper"
require "json"
include BVT::Spec

describe "Performance::AppPerformance" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    show_crashlogs
    @session.cleanup!
  end

  def health_check(app)
    response = app.get_response(:get, '/healthcheck')
    response.should_not == nil
    response.to_str.should =~ /^OK/
    response.code.should == 200
  end

  def incr_counter(app, number)
    number.times do
      sleep 0.02
      response = app.get_response(:get, '/incr')
      response.should_not == nil
      response.to_str.should =~ /^OK:/
      response.code.should == 200
    end
  end

  def check_sum_instances(app, number, sum=true)
    response = app.get_response(:get, '/getstats')
    response.should_not == nil
    response.code.should == 200
    counters = JSON.parse(response.to_str)

    total_count = 0
    counters.each do |k,v|
      total_count += sum ? v.to_i : 1
    end
    total_count.should == number
  end

  def reset_counter(app)
    response = app.get_response(:get, '/reset')
    response.should_not == nil
    response.to_str.should =~ /^OK/
    response.code.should == 200

    response = app.get_response(:get, '/getstats')
    response.should_not == nil
    response.to_str.should =~ /^\{\}/
    response.code.should == 200
  end

  it "deploy redis lb app" do
    app = create_push_app("redis_lb_app", nil, nil, [REDIS_MANIFEST])
    health_check(app)

    incr_counter(app, 5)
    reset_counter(app)

    app.total_instances = 5
    app.update!
    app.instances.length.should == 5

    sleep 1
    incr_counter(app, 5)
    reset_counter(app)
    app.restart
    sleep 1

    incr_counter(app, 150)
    check_sum_instances(app, 150)
    check_sum_instances(app, 5, false)

    response = app.get_response(:get, '/getstats')
    response.should_not == nil
    response.code.should == 200
    counters = JSON.parse(response.to_str)

    counters.each do |k,v|
      v.to_i.should be_within(16.5).of(30)
    end
  end

  it "deploy env_test app" do
    app = create_push_app("env_test_app")
    should_be_there = []

    v = "redis"
    myname = "#{v}my-#{v}"
    manifest = REDIS_MANIFEST

    # then record for testing against the environment variables
    manifest[:name] = myname
    service = create_service(manifest, myname)
    app.bind(service)
    should_be_there << manifest

    services = app.services
    services.should_not == nil

    response = app.get_response(:get, '/services')
    response.should_not == nil
    response.code.should == 200
    service_list = JSON.parse(response.to_str)

    # assert that the services list that we get from the app environment
    # matches what we expect from provisioning
    found = 0
    service_list['services'].each do |s|
      should_be_there.each do |v|
        if v[:name] == s['name'] && v[:vendor] == s['vendor']
          found += 1
          break
        end
      end
    end
    found.should == should_be_there.length

    health_check(app)
  end

end
