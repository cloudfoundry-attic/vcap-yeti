require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Ruby18Rails3 do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "access my application root and see it's running version 1.8.7" do
    @app = create_app("app_rails_version18")
    @app.push
    @app.healthy?.should be_true, "Application #{@app.name} is not running"
    @app.stats.should_not == nil
    @app.get_response(:get).should_not == nil
    @app.get_response(:get).body_str.should_not == nil
    @app.get_response(:get).body_str.should == "running version 1.8.7"
  end
end
