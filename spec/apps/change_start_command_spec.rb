require "harness"
require "spec_helper"
require "securerandom"
include BVT::Spec

describe "Changing an app's start command" do
  before(:all) { @session = BVT::Harness::CFSession.new }

  after(:all) { @session.cleanup! }

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

  def asset(path)
    File.expand_path("../../../assets/#{path}", __FILE__)
  end

  def make_app
    @session.client.app.tap do |app|
      app.name = SecureRandom.uuid
    end
  end

  def map_route(app, host = SecureRandom.uuid, domain = @session.client.domains.first)
    route = @session.client.route
    route.host = host
    route.domain = domain
    route.space = app.space
    route.create!

    app.add_route(route)
  end

  def get_endpoint(app, path)
    Net::HTTP.get(URI.parse("http://#{app.url}#{path}"))
  end

  def staging_callback(blk = nil)
    proc do |url|
      next unless url

      if blk
        blk.call(url)
      elsif url
        stream_update_log(url) do |chunk|
          puts "       STAGE LOG => #{chunk}"
        end
      end
    end
  end

  def stream_update_log(log_url)
    offset = 0

    while true
      begin
        @session.client.stream_url(log_url + "&tail&tail_offset=#{offset}") do |out|
          offset += out.size
          yield out
        end
      rescue Timeout::Error
      end
    end
  rescue CFoundry::APIError
  end
end