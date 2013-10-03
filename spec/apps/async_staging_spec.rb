require "harness"
require "spec_helper"
include BVT::Spec

describe "Async app staging" do
  before(:all) { @session = BVT::Harness::CFSession.new }

  after { @session.cleanup! }

  it "successfully finishes staging of the app" do
    staging_log_url = nil

    # create and push the app
    app = create_app("standalone_ruby_app")

    app.manifest["no_start"] = true
    app.create_app("standalone_ruby_app#{rand(65046056)}", app.manifest["path"], nil, false)

    app.start(!:need_check) do |url|
      staging_log_url = url
    end

    # tail staging log
    tail_uri = staging_log_url + "&tail_offset=0&tail"
    tailed_log = ""

    app.stream_log(tail_uri) do |chunk|
      tailed_log << chunk
    end

    tailed_log.should =~ /Using Ruby/
    tailed_log.should =~ /Your bundle is complete!/

    # check app is running
    app.check_application
    app.get_response(:get).to_str.should =~ /running version/
  end
end
