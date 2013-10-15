require "harness"
require "spec_helper"
require "securerandom"
include BVT::Spec

describe "Network Lockdown", :runtime => true do
  before(:all) { @session = BVT::Harness::CFSession.new }
  after(:all) { @session.cleanup! if @session }

  with_app "connect_to_ip"

  def request(target)
    ip = ENV["VCAP_BVT_#{target.to_s.upcase}_IP"]
    port = ENV["VCAP_BVT_#{target.to_s.upcase}_PORT"]
    pending "#{target.to_s} uri info not configured for this run" unless ip && port
    app.get_response(:get, "/#{ip}/#{port}", "", nil, 100)
  end

  it 'should connect to allowed ports' do
    res = app.get_response(:get, "/4.2.2.1/53", "", nil, 100)
    res.to_str.should =~ /is open/
  end

  it 'should connect to github' do
    res = app.get_response(:get, "/github.com/80", "", nil, 100)
    res.to_str.should =~ /is open/
  end

  it 'should connect to rubygems' do
    res = app.get_response(:get, "/rubygems.org/80", "", nil, 100)
    res.to_str.should =~ /is open/
  end

  describe "internal address", exclude_in_warden_cpi: true  do
    it 'should connect to amazon dns' do
      res = request(:ec2_dns)
      res.to_str.should =~ /is open/
    end

    it 'should not be able to talk to NATS' do
      res = request(:nats)
      res.to_str.should =~ /is NOT open/
    end

    it 'should not be able to talk to CC' do
      res = request(:cc)
      res.to_str.should =~ /is NOT open/
    end

    it 'should not be able to talk to gorouter' do
      res = request(:gorouter)
      res.to_str.should =~ /is NOT open/
    end

    it 'should not be able to talk to CCDB' do
      pending "wont pass until we split RDS's into two subnets"
      res = request(:ccdb)
      res.to_str.should =~ /is NOT open/
    end

    it 'should not be able to talk to UAA' do
      res = request(:uaa)
      res.to_str.should =~ /is NOT open/
    end

    it 'should not be able to talk to UAADB' do
      pending "wont pass until we split RDS's into two subnets"
      res = request(:uaadb)
      res.to_str.should =~ /is NOT open/
    end

    it 'should not be able to talk to login' do
      res = request(:login)
      res.to_str.should =~ /is NOT open/
    end

    it 'should not be able to talk to BOSH' do
      res = request(:bosh)
      res.to_str.should =~ /is NOT open/
    end

    it 'should not be able to talk to loggregator' do
      res = request(:loggregator)
      res.to_str.should =~ /is NOT open/
    end

    it 'should not be able to talk to loggregator trafficcontroller' do
      res = request(:loggregator_trafficcontroller)
      res.to_str.should =~ /is NOT open/
    end

    it 'should not be able to talk to EC2 status endpoint' do
      res = request(:ec2_status_endpoint)
      res.to_str.should =~ /is NOT open/
    end

    it 'should be able to talk through the CF front-doors' do
      service_list = %w[login uaa api]
      domain = ::URI.parse(ENV['VCAP_BVT_API_ENDPOINT']).host.split('.', 2).last
      service_list.each do |s|
        res = app.get_response(:get, "/#{s}.#{domain}/80", "", nil, 100)
        res.to_str.should =~ /is open/
      end
    end
  end
end

