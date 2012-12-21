require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Simple::RubyRails3 do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "access my application root and see it's running version" do
    @app = create_push_app("app_rails_version")
    @app.stats.should_not == nil

    runtime = @app.manifest['runtime']
    version = VCAP_BVT_SYSTEM_RUNTIMES[runtime][:version].split("p",2).first
    @app.get_response(:get).should_not == nil
    @app.get_response(:get).to_str.should_not == nil
    @app.get_response(:get).to_str.should == "running version "+version
  end

  it "precompiles assets" do
    @app = create_push_app("rails_3_2_app")
    @app.stats.should_not == nil
    res = @app.get_response(:get, "/assets/manifest.yml")
    res.should_not == nil
    res.to_str.should match /application.js: application-\w/
    res = @app.get_response(:get, "/assets/application.js")
    res.to_str.should match /alert\(\"Hello from CoffeeScript!\"\)/
  end

end
