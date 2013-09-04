require "harness"
require "spec_helper"
require "logs-cf-plugin/plugin"

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
  let(:loggregator_client) { LogsCfPlugin::LoggregatorClient.new(loggregator_host, cf_client.token.auth_header, loggregator_io, false) }
  let(:cf_client) { @session.client }

  def loggregator_host
    target_base = @session.api_endpoint.sub(/^https?:\/\/([^\.]+\.)?(.+)\/?/, '\2')
    "loggregator.#{target_base}"
  end

  it "can tail app logs" do
    th = Thread.new do
      loggregator_client.listen(@app)
    end

    @app.start

    # Check that we get logs before we time out. If we don't, this test should fail.
    Timeout.timeout(10) do
      until loggregator_io.string =~ /STDOUT stdout log/ &&
          loggregator_io.string =~ /STDERR stderr log/ &&
          loggregator_io.string =~ /CF\[Router\]  STDOUT #{@app.get_url}/ &&
          loggregator_io.string =~ /CF\[DEA\]  STDOUT/ &&
          loggregator_io.string =~ /CF\[CC\]  STDOUT/
        @app.get('/logs')
        sleep(0.5)
      end
    end

    Thread.kill(th)
  end
end
