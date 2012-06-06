require "harness"
require "spec_helper"

describe BVT::Spec::AppPerformance::Ruby19Sinatra do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def health_check(app)
    response = app.get_response(:get, '/healthcheck')
    response.should_not == nil
    response.body_str.should =~ /^OK/
    response.response_code.should == 200
    response.close
  end

  def incr_counter(app, number)
    number.times do
      response = app.get_response(:get, '/incr')
      response.should_not == nil
      response.body_str.should =~ /^OK:/
      response.response_code.should == 200
      response.close
    end
  end

  def check_sum_instances(app, number, sum=true)
    response = app.get_response(:get, '/getstats')
    response.should_not == nil
    response.response_code.should == 200
    counters = JSON.parse(response.body_str)
    response.close

    total_count = 0
    counters.each do |k,v|
      total_count += sum ? v.to_i : 1
    end
    total_count.should == number
  end

  def reset_counter(app)
    response = app.get_response(:get, '/reset')
    response.should_not == nil
    response.body_str.should =~ /^OK/
    response.response_code.should == 200
    response.close

    response = app.get_response(:get, '/getstats')
    response.should_not == nil
    response.body_str.should =~ /^\{\}/
    response.response_code.should == 200
    response.close
  end

  it "deploy redis lb app", :redis => true do
    app = create_push_app("redis_lb_app")
    bind_service(REDIS_MANIFEST, app)
    health_check(app)

    reset_counter(app)
    incr_counter(app, 10)
    check_sum_instances(app, 10)
    reset_counter(app)

    manifest = {}
    manifest['instances'] = 5
    app.update!(manifest)
    app.instances.length.should == 5

    incr_counter(app, 150)
    check_sum_instances(app, 150)
    check_sum_instances(app, 5, false)

    response = app.get_response(:get, '/getstats')
    response.should_not == nil
    response.response_code.should == 200
    counters = JSON.parse(response.body_str)
    response.close

    counters.each do |k,v|
      v.to_i.should be_within(16.5).of(30)
    end
  end

  it "deploy env_test app" do
    app = create_push_app("env_test_app")

    should_be_there = []
    ["aurora", "redis"].each do |v|
      if BVT::Harness::VCAP_BVT_SYSTEM_SERVICES.has_key?(v)
        # create named service
        myname = "#{v}my-#{v}"
        if v == 'aurora'
          manifest = {"vendor"=>"aurora"}
        end
        if v == 'redis'
          manifest = REDIS_MANIFEST
        end

        # then record for testing against the environment variables
        manifest['name'] = myname
        service = create_service(manifest, app, myname)
        app.bind(service.name)
        should_be_there << manifest
      end
    end

    services = app.services
    services.should_not == nil

    response = app.get_response(:get, '/services')
    response.should_not == nil
    response.response_code.should == 200
    service_list = JSON.parse(response.body_str)
    response.close

    # assert that the services list that we get from the app environment
    # matches what we expect from provisioning
    found = 0
    service_list['services'].each do |s|
      should_be_there.each do |v|
        if v[:name] == s[:name] && v[:vendor] == s[:vendor]
          found += 1
          break
        end
      end
    end
    found.should == should_be_there.length

    health_check(app)
  end

end
