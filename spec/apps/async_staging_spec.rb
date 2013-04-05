require "harness"
require "spec_helper"
include BVT::Spec

describe "Async app staging" do
  before(:all) { @session = BVT::Harness::CFSession.new }
  after(:each) do
    @session.cleanup!
  end

  def step(name)
    yield
  end

  it "successfully finishes staging of the app" do
    app = nil
    staging_log_url = nil

    step "create and push the app" do
      app = create_app("standalone_ruby_app")

      app.manifest["no_start"] = true
      app.create_app("standalone_ruby_app#{rand(65046056)}", app.manifest["path"], nil, false)

      app.start(!:need_check) do |url|
        staging_log_url = url
      end
    end

    step "tail staging log" do
      tail_uri = staging_log_url + "&tail_offset=0&tail"
      tailed_log = ""

      app.stream_log(tail_uri) do |chunk|
        tailed_log << chunk
      end

      tailed_log.should match /Using Ruby/
      tailed_log.should match /Your bundle is complete!/
    end

    step "check app is running" do
      app.check_application
      app.get_response(:get).to_str.should == "running version 1.9.2"
    end
  end
end
