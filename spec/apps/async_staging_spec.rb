require "harness"
require "spec_helper"
include BVT::Spec

describe "Async app staging", :runtime => true do
  before { @session = BVT::Harness::CFSession.new }

  after { @session.cleanup! }

  it "successfully finishes staging of the app" do
    app = make_app
    app.create!

    map_route(app)

    app.upload(asset("sinatra/dora"))

    tailed_log = ""

    app.start! do |staging_log_url|
      stream_update_log(staging_log_url) do |chunk|
        puts "       STAGE LOG => #{chunk}"
        tailed_log << chunk
      end
    end

    tailed_log.should =~ /Using Ruby/
    tailed_log.should =~ /Your bundle is complete!/

    wait { expect(app.running?).to be_true }

    expect(get_endpoint(app, "/")).to match(/Hello from VCAP!/)
  end
end
