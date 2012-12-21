require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Simple::RubyStandalone do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def get_version(app)
    runtime = app.manifest['runtime']
    VCAP_BVT_SYSTEM_RUNTIMES[runtime][:version].split("p",2).first
  end

  it "Bundled app with ruby runtime" do
    app = create_push_app("standalone_ruby_app")
    app.get_response(:get).to_str.should == "running version #{get_version(app)}"
  end

  it "Simple app with ruby runtime and no URL", :p1 => true do
    app = create_push_app("standalone_simple_ruby_app")
    app.logs =~ /running version #{get_version(app)}/
  end

  it "With quotes in command" do
    app = create_push_app("standalone_simple_ruby_quotes_app")
    app.logs =~ /running version #{get_version(app)}/
  end
end
