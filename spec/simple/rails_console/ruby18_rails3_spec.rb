require "harness"
require "spec_helper"
require "vmc"
require "cli"

$:.unshift(File.join(File.dirname(__FILE__)))
require "rails_console_helper"

describe BVT::Spec::Simple::RailsConsole::Ruby18Rails3 do
  include BVT::Spec, BVT::Harness, BVT::Spec::RailsConsoleHelper

  before(:all) do
    @session = BVT::Harness::CFSession.new
    cfoundry = CFoundry::Client.new(@session.TARGET)
    @token = cfoundry.login(:username => @session.email, :password => @session.passwd)
    @client = VMC::Client.new(@session.TARGET, @token)
    @session.log.debug("client token: #{@token}")
    @console_cmd = VMC::Cli::Command::Apps.new
    @console_cmd.client(@client)
  end

  after(:each) do
    @session.cleanup!
  end

  it "rails test console", :p1 => true do
    app = create_push_app("rails_console_test_app")
    manifest = {}
    manifest["console"] = true
    app.update!(manifest)
    @console_cmd.restart(app.name)

    run_console(app.name)
    expected_results = ["irb():001:0> "]
    expected_results.should == @console_response

    2.times do
      begin
        @console_response = @console_cmd.send_console_command("app.class")
        break
      rescue EOFError => e
        @session.log.debug("Fail to connect rails console, retrying. #{e.to_s}")
      end
    end

    expected_results = ("app.class,=> ActionDispatch::Integration::Session,irb" +
                      "():002:0> ").split(",")
    expected_results.should == @console_response
    @console_cmd.close_console if @console_cmd
  end

  it "rails test console tab completion" do
    app = create_push_app("rails_console_test_app")
    manifest = {}
    manifest["console"] = true
    app.update!(manifest)

    @console_cmd.restart(app.name)

    run_console(app.name)

    expected_results = ["irb():001:0> "]
    expected_results.should == @console_response

    @console_cmd.console_tab_completion_data("puts")
    @console_tab_response = @console_cmd.console_tab_completion_data("puts")
    expected_results = ["puts"]
    expected_results.should == @console_tab_response

    @console_cmd.close_console if @console_cmd
  end

  it "rails test console stdout redirect" do
    app = create_push_app("rails_console_test_app")
    manifest = {}
    manifest["console"] = true
    app.update!(manifest)

    @console_cmd.restart(app.name)

    run_console(app.name)

    expected_results = ["irb():001:0> "]
    expected_results.should == @console_response

    @console_response = @console_cmd.send_console_command("puts 'hi'")
    expected_results = ("puts 'hi',hi,=> nil,irb():002:0> ").split(",")
    expected_results.should == @console_response

    @console_cmd.close_console if @console_cmd
  end

  it "rails test console rake tasks" do
    app = create_push_app("rails_console_test_app")
    manifest = {}
    manifest["console"] = true
    app.update!(manifest)

    @console_cmd.restart(app.name)

    run_console(app.name)

    expected_results = ["irb():001:0> "]
    expected_results.should == @console_response

    2.times do
      begin
        @console_response = @console_cmd.send_console_command("`rake routes`")
        break
      rescue EOFError => e
        @session.log.debug("Fail to send console command, retrying. #{e.to_s}")
      end
    end

    matched = false
    @console_response.each do |response|
      matched = true if response=~ /#{Regexp.escape(':action=>\"hello\"')}/
    end
    matched.should == true

    @console_cmd.close_console if @console_cmd
  end

  it "Rails Console runs tasks with correct ruby 1.8 version in path" do
    app = create_push_app("rails_console_test_app")
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
      matched = true if response=~ /#{Regexp.escape("ruby 1.8")}/
    end
    matched.should == true

    @console_cmd.close_console if @console_cmd
  end

end
