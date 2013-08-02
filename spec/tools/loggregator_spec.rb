require "harness"
require "spec_helper"
require "tail-cf-plugin/loggregator_client"
include BVT::Spec

describe "Tools::Loggregator" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
    @app = create_push_app('node0_6', '', nil, [], true)
  end

  after(:all) do
    @session.cleanup!
  end

  let(:loggregator_io) { StringIO.new }
  let(:loggregator_client) { TailCfPlugin::LoggregatorClient.new(loggregator_io) }
  let(:cf_client) { @session.client }

  def loggregator_host
    target_base = @session.api_endpoint.sub(/^https?:\/\/([^\.]+\.)?(.+)\/?/, '\2')
    "loggregator.#{target_base}"
  end

  it 'can tail app logs' do
    th = Thread.new do
      loggregator_client.listen(loggregator_host, cf_client.current_space.guid, @app.guid, cf_client.token.auth_header)
    end

    @app.start
    @app.get('/logs')
    Thread.kill(th)

    output_lines = loggregator_io.string.split("\n")
    expect(output_lines.first).to match /Connected to server/
    #expect(output_lines.last).to match /Server dropped connection/
    expect(output_lines).to include(match /(\w+-){4}\w+\s+STDOUT stdout log/)
    expect(output_lines).to include(match /(\w+-){4}\w+\s+STDERR stderr log/)
  end

  it 'can tail space logs' do
    th = Thread.new do
      loggregator_client.listen(loggregator_host, cf_client.current_space.guid, nil, cf_client.token.auth_header)
    end

    @app.start
    @app.get('/logs')
    Thread.kill(th)

    output_lines = loggregator_io.string.split("\n")
    expect(output_lines.first).to match /Connected to server/
    #expect(output_lines.last).to match /Server dropped connection/
    expect(output_lines).to include(match /(\w+-){4}\w+\s+STDOUT stdout log/)
    expect(output_lines).to include(match /(\w+-){4}\w+\s+STDERR stderr log/)
  end
end