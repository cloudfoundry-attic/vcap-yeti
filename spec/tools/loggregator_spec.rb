# encoding: UTF-8

require "harness"
require "spec_helper"
require "logs-cf-plugin/plugin"

include BVT::Spec

describe "Tools::Loggregator" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
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

  with_app "loggregator"

  it "can tail app logs" do

    th = Thread.new do
      loggregator_client.logs_for(app)
    end

    # We need to restart the app after the loggregator tail is running so we can test various logs
    app.restart

    begin
      Timeout.timeout(10) do
        loop { break if app.application_is_really_running? }
      end
    rescue Timeout::Error
      raise "Loggregator test app didn't startup correctly"
    end

    matchers = {}
    matchers[/Hello on STDOUT/] =  false
    matchers[/Hello on STDERR/] =  false
    matchers[/CF\[Router(\/\d)?\] STDOUT #{app.get_url}/] =  false
    matchers[/CF\[CC(\/\d)?\] STDOUT/] =  false
    matchers[/CF\[DEA(\/\d)?\] STDOUT/] =  false

    # Check that we get logs before we time out. If we don't, this test should fail.
    begin
      Timeout.timeout(10) do
        while true
          result = app.get_response(:get)

          raise "Could not get response from loggregator test app" if result.code.to_i != 200

          logged_output = loggregator_io.string

          if logged_output =~ /Server dropped connection/
            raise "Connection dropped! Output:\n#{logged_output}\n\nEvents:#{app.events.inspect}"
          end

          matchers.each do |matcher, matched|
            next if matched
            if logged_output =~ matcher
              puts "LOGS MATCH #{matcher}"
              matchers[matcher]=true
            else
              puts "LOGS DO NOT MATCH #{matcher}?"
            end
          end

          break if matchers.values.all? { |matched| matched }

          sleep(0.5)
        end
      end
    rescue Timeout::Error
      raise "Did not see matching lines. Output:\n#{loggregator_io.string}\n\nEvents:#{app.events.inspect}"
    ensure
      Thread.kill(th)
    end
  end
end
