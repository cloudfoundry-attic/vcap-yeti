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

  let(:loggregator_client_config) do
    loggregator_port, use_ssl =
      if @session.api_endpoint.start_with?("https")
        [4443, true]
      else
        [80, false]
      end

    LogsCfPlugin::ClientConfig.new(
      loggregator_host,
      loggregator_port,
      cf_client.token.auth_header,
      loggregator_io,
      false,
      use_ssl,
    )
  end

  let(:loggregator_client) do
    LogsCfPlugin::TailingLogsClient.new(loggregator_client_config)
  end

  let(:cf_client) { @session.client }

  def loggregator_host
    target_base = @session.api_endpoint.sub(/^https?:\/\/([^\.]+\.)?(.+)\/?/, '\2')
    "loggregator.#{target_base}"
  end

  it "can tail app logs" do
    th = Thread.new do
      loggregator_client.logs_for(@app)
    end

    @app.start

    # Check that we get logs before we time out. If we don't, this test should fail.
    begin
      Timeout.timeout(10) do
        while true
          logged_output = loggregator_io.string

          if logged_output =~ /Server dropped connection/
            raise "Connection dropped! Output:\n#{logged_output}"
          end

          matches = [
            /STDOUT stdout log/,
            /STDERR stderr log/,
            /CF\[Router\] STDOUT #{@app.get_url}/,
          ]

          break if matches.all? { |match|
            if logged_output =~ match
              puts "LOGS MATCH #{match}"
              true
            else
              puts "LOGS DO NOT MATCH #{match}?"
              false
            end
          }

          @app.get('/logs')

          sleep(0.5)
        end
      end
    rescue Timeout::Error
      raise "Did not see matching lines. Output:\n#{loggregator_io.string}"
    end

    Thread.kill(th)
  end
end
