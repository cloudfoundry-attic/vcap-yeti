require "harness"
require "spec_helper"

describe BVT::Spec::AutoStaging::Ruby19Rack do

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

  it "rack ruby 1.9 autostaging" do
    manifest = {"instances"=>1,
                "staging"=>{"framework"=>"rack", "runtime"=>"ruby19"},
                "resources"=>{"memory"=>64}}
    app = @session.app("rack_autoconfig_ruby19")
    app.push(manifest)
    app.healthy?.should be_true, "Application #{app.name} is not running"
    app.get_response(:get).body_str.should == "hello from sinatra"

    # provision service
    service_manifest = {"vendor"=>"redis", "version"=>"2.2"}
    bind_service(service_manifest, app)
    key = "abc"
    data = "#{service_manifest['vendor']}#{key}"
    app.get_response(:post, "/service/#{service_manifest['vendor']}/#{key}", data)
    app.get_response(:get, "/service/#{service_manifest['vendor']}/#{key}").body_str.should == data
  end
end
