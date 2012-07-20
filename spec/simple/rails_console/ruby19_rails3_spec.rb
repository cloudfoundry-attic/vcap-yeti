require "harness"
require "spec_helper"
require "vmc"
require "cli"

$:.unshift(File.join(File.dirname(__FILE__)))
require "rails_console_helper"

describe BVT::Spec::Simple::RailsConsole::Ruby19Rails3 do
  include BVT::Spec, BVT::Harness, BVT::Spec::RailsConsoleHelper

  before(:all) do
    @session = BVT::Harness::CFSession.new
    @client = VMC::Client.new(@session.TARGET)
    @token = @client.login(@session.email, @session.passwd)
    @console_cmd = VMC::Cli::Command::Apps.new
    @console_cmd.client(@client)
  end

  after(:each) do
    @session.cleanup!
  end

  it "rails test console rake tasks with ruby 1.9" do
    app = create_push_app("rails_console_19_test_app")
    manifest = {}
    manifest["console"] = true
    app.update!(manifest)

    @console_cmd.restart(app.name)

    run_console(app.name)

    expected_results = ["irb():001:0> "]
    expected_results.should == @console_response

    @console_response = @console_cmd.send_console_command("`rake routes`")
    matched = false
    @console_response.each do |response|
      matched = true if response=~ /#{Regexp.escape(':action=>\"index\"')}/
    end
    matched.should == true

    @console_cmd.close_console if @console_cmd
  end

  it "Rails Console runs tasks with correct ruby 1.9 version in path" do
    app = create_push_app("rails_console_19_test_app")
    manifest = {}
    manifest["console"] = true
    app.update!(manifest)

    @console_cmd.restart(app.name)

    run_console(app.name)

    expected_results = ["irb():001:0> "]
    expected_results.should == @console_response

    @console_response = @console_cmd.send_console_command("`ruby --version`")
    matched = false
    @console_response.each do |response|
      matched = true if response=~ /#{Regexp.escape("ruby 1.9")}/
    end
    matched.should == true

    @console_cmd.close_console if @console_cmd
  end
end
