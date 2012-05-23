require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Ruby19Sinatra do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "access my application root and see hello from sinatra" do
    @app = create_push_app("broken_gem_app")
    @app.stats.should_not == nil
    @app.get_response(:get).should_not == nil
    @app.get_response(:get).body_str.should_not == nil
    @app.get_response(:get).body_str.should == "hello from sinatra"
  end
end
