require "harness"
require "spec_helper"

describe "Changing an app's start command", :runtime => true do
  before { @session = BVT::Harness::CFSession.new }

  after { @session.cleanup! }

  it "does not require the app to be pushed again" do
    command = "bundle exec ruby explore.rb -p $PORT"

    app = make_app
    app.command = "FOO=foo #{command}"
    app.create!

    map_route(app)

    app.upload(asset("sinatra/dora"))
    app.start!(&staging_callback)

    sleep 1 until app.running?

    expect(get_endpoint(app, "/env/FOO")).to eq("foo")

    app.command = "FOO=bar #{command}"
    app.restart!(&staging_callback)

    sleep 1 until app.running?

    expect(get_endpoint(app, "/env/FOO")).to eq("bar")
  end
end
