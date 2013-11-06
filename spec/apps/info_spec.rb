require "harness"
require "spec_helper"

describe "Dynamic app information", :runtime => true do
  before(:all) do
    @session = BVT::Harness::CFSession.new

    @app = make_app
    @app.create!

    map_route(@app)

    @app.upload(asset("sinatra/dora"))
    @app.start!(&staging_callback)

    wait { expect(@app).to be_running }
  end

  after(:all) { @session.cleanup! }

  it "can be queried for stats" do
    stats = @app.stats
    expect(stats.size).to eq(@app.total_instances)
    expect(stats["0"][:state]).to eq("RUNNING")
  end

  it "can have its files inspected" do
    @app.files("/").should_not be_nil
    @app.files("/app").should_not be_nil
    @app.files("/app/config.ru").should_not be_nil
  end

  it "can be queried for instances" do
    expect {
      @app.total_instances = @app.total_instances + 1
      @app.update!

      wait(100) { expect(@app).to be_running }
    }.to change { @app.instances.size }.by(1)
  end

  it "can be queried for crashes" do
    expect(@app.crashes).to be_empty

    get_endpoint(@app, "/sigterm/KILL")

    wait do
      expect(@app.crashes).to_not be_empty

      stdout = @app.crashes.first.file("logs/stdout.log")
      expect(stdout).to match(/Killing process \d+ with signal KILL/)
    end
  end
end