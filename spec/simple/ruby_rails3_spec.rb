require "harness"
require "spec_helper"
include BVT::Spec

describe "Simple::RubyRails3" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    show_crashlogs
    @session.cleanup!
  end

  it "access my application root and see it's running version" do
    @app = create_push_app("app_rails_version", nil, nil, [MYSQL_MANIFEST])
    @app.stats.should_not == nil

    @app.get_response(:get).should_not == nil
    @app.get_response(:get).to_str.should_not == nil
    @app.get_response(:get).to_str.should == "running version 1.9.2"
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
