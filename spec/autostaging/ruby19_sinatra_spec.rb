require "harness"
require "spec_helper"

describe BVT::Spec::AutoStaging::Ruby19Sinatra do

  before(:each) do
    @client = BVT::Harness::CFSession.new
  end

  after(:each) do
    @client.cleanup!
  end

  def bind_service(service_manifest, app)
    service = @client.service(service_manifest['vendor'])
    service.create(service_manifest)
    app.bind(service.name)
  end

  def verify_service_autostaging(service_manifest, app)
    key = "abc"
    data = "#{service_manifest['vendor']}#{key}"
    if service_manifest['vendor'] == 'mongodb'
      #TODO
      # once switch to yeti entirely, need to change app_sinatra_service_autoconfig in assets
      # in order to keep url consist with service vendor name
      # and then remove following two statements.
      app.get_response(:post, "/service/mongo/#{key}", data)
      app.get_response(:get, "/service/mongo/#{key}").body_str.should == data
    else
      app.get_response(:post, "/service/#{service_manifest['vendor']}/#{key}", data)
      app.get_response(:get, "/service/#{service_manifest['vendor']}/#{key}").body_str.should == data
    end
  end

  def verify_unsupported_client_version(service_manifest, app, data)
    key = "connection"
    case service_manifest['vendor']
      when 'mongodb'
        #TODO
        # once switch to yeti entirely, need to change autoconfig_unsupported_versions in assets
        # in order to keep url consist with service vendor name
        # and then remove following two statements.
        app.get_response(:get, "/service/mongo/#{key}").body_str.should == data
      when 'rabbitmq'
        app.get_response(:get, "/service/amqp/#{key}").body_str.should == data
      when 'postgresql'
        app.get_response(:get, "/service/postgres/#{key}").body_str.should == data
      else
        app.get_response(:get, "/service/#{service_manifest['vendor']}/#{key}").body_str.should == data
    end
  end

  it "services autostaging" do
    manifest = {"instances"=>1,
                "staging"=>{"framework"=>"sinatra", "runtime"=>"ruby19"},
                "resources"=>{"memory"=>64}}
    app = @client.app("app_sinatra_service_autoconfig")
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

  it "Sinatra AMQP autostaging" do
    manifest = {"instances"=>1,
                "staging"=>{"framework"=>"sinatra", "runtime"=>"ruby19"},
                "resources"=>{"memory"=>64}}
    app = @client.app("amqp_autoconfig")
    app.push(manifest)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = {"vendor"=>"rabbitmq", "version"=>"2.4"}
    bind_service(service_manifest, app)
    data = "#{service_manifest['vendor']}abc"
    app.get_response(:post, "/service/amqpurl/abc", data)
    app.get_response(:get, "/service/amqpurl/abc").body_str.should == data

    app.get_response(:post, "/service/amqpoptions/abc", data)
    app.get_response(:get, "/service/amqpoptions/abc").body_str.should == data
  end

  it "Autostaging with unsupported client versions" do
    manifest = {"instances"=>1,
                "staging"=>{"framework"=>"sinatra", "runtime"=>"ruby19"},
                "resources"=>{"memory"=>64}}
    app = @client.app("autoconfig_unsupported_versions")
    app.push(manifest)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    testdata = [{:service => {"vendor"=>"mysql", "version"=>"5.1"},
                 :data => "Can'tconnecttoMySQLserveron'127.0.0.1'(111)"},
                {:service => {"vendor"=>"redis", "version"=>"2.2"},
                 :data => "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"},
                {:service => {"vendor"=>"rabbitmq", "version"=>"2.4"},
                 :data => "Couldnotconnecttoserver127.0.0.1:4567"},
                {:service => {"vendor"=>"postgresql", "version"=>"9.0"},
                 :data => "couldnotconnecttoserver:ConnectionrefusedIstheserverrunningonhost\"127.0.0.1\"andacceptingTCP/IPconnectionsonport8675?"},
                {:service => {"vendor"=>"mongodb", "version"=>"1.8"},
                 :data => "Failedtoconnecttoamasternodeat127.0.0.1:4567"}]
    testdata.each do |item|
      bind_service(item[:service], app)
      verify_unsupported_client_version(item[:service], app, item[:data])
    end
  end

  it "Autostaging with unsupported carrot version" do
    manifest = {"instances"=>1,
                "staging"=>{"framework"=>"sinatra", "runtime"=>"ruby19"},
                "resources"=>{"memory"=>64}}
    app = @client.app("autoconfig_unsupported_carrot_version")
    app.push(manifest)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = {"vendor"=>"rabbitmq", "version"=>"2.4"}
    bind_service(service_manifest, app)
    data = "Connectionrefused-connect(2)-127.0.0.1:1234"
    app.get_response(:get, "/service/carrot/connection").body_str.should == data
  end

  it "Sinatra opt-out of autostaging via config file" do
    manifest = {"instances"=>1,
                "staging"=>{"framework"=>"sinatra", "runtime"=>"ruby19"},
                "resources"=>{"memory"=>64}}
    app = @client.app("sinatra_autoconfig_disabled_by_file")
    app.push(manifest)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = {"vendor"=>"redis", "version"=>"2.2"}
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    app.get_response(:get, "/service/#{service_manifest['vendor']}/connection").body_str.should == data
  end

  it "Sinatra opt-out of autostaging via cf-runtime gem" do
    manifest = {"instances"=>1,
                "staging"=>{"framework"=>"sinatra", "runtime"=>"ruby19"},
                "resources"=>{"memory"=>64}}
    app = @client.app("sinatra_autoconfig_disabled_by_gem")
    app.push(manifest)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = {"vendor"=>"redis", "version"=>"2.2"}
    bind_service(service_manifest, app)
    data = "Connectionrefused-UnabletoconnecttoRedison127.0.0.1:6379"
    app.get_response(:get, "/service/#{service_manifest['vendor']}/connection").body_str.should == data
  end
end
