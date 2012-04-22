require "harness"
require "spec_helper"

describe BVT::Spec::AutoStaging::Ruby18Rack do

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def bind_service(service_manifest, app)
    service = @session.service(service_manifest['vendor'])
    service.create(service_manifest)
    app.bind(service.name)
  end

  def verify_service_autostaging(service_manifest, app)
    key = "abc"
    data = "#{service_manifest['vendor']}#{key}"
    url = "/service/#{service_manifest['vendor']}/#{key}"
    if service_manifest['vendor'] == 'mongodb'
      #TODO
      # once switch to yeti entirely, need to change app_sinatra_service_autoconfig in assets
      # in order to keep url consist with service vendor name
      # and then remove following two statements.
      app.get_response(:post, "/service/mongo/#{key}", data)
      app.get_response(:get, "/service/mongo/#{key}").body_str.should == data
    else
      app.get_response(:post, url, data)
      app.get_response(:get, url).body_str.should == data
    end
  end

  it "services autostaging" do
    manifest = {"instances"=>1,
                "staging"=>{"framework"=>"rack", "runtime"=>"ruby18"},
                "resources"=>{"memory"=>64}}
    app = @session.app("app_rack_service_autoconfig")
    app.push(manifest)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get, "/crash").body_str.should =~ /502 Bad Gateway/

    # provision service
    manifests = [{"vendor"=>"mysql", "version"=>"5.1"},
                 {"vendor"=>"redis", "version"=>"2.2"},
                 {"vendor"=>"mongodb", "version"=>"1.8"},
                 {"vendor"=>"rabbitmq", "version"=>"2.4"},
                 {"vendor"=>"postgresql", "version"=>"9.0"}]
    manifests.each do |service_manifest|
      bind_service(service_manifest, app)
      verify_service_autostaging(service_manifest, app)
    end
  end

  it "rack opt-out of autostaging via config file" do
    manifest = {"instances"=>1,
                "staging"=>{"framework"=>"rack", "runtime"=>"ruby18"},
                "resources"=>{"memory"=>64}}
    app = @session.app("rack_autoconfig_disabled_by_file")
    app.push(manifest)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = {"vendor"=>"redis", "version"=>"2.2"}
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    url = "/service/#{service_manifest['vendor']}/connection"
    app.get_response(:get, url).body_str.should == data
  end

  it "rack opt-out of autostaging via cf-runtime gem" do
    manifest = {"instances"=>1,
                "staging"=>{"framework"=>"rack", "runtime"=>"ruby18"},
                "resources"=>{"memory"=>64}}
    app = @session.app("rack_autoconfig_disabled_by_gem")
    app.push(manifest)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = {"vendor"=>"redis", "version"=>"2.2"}
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    url = "/service/#{service_manifest['vendor']}/connection"
    app.get_response(:get, url).body_str.should == data
  end
end
