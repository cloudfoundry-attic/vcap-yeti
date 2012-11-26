require "harness"
require "spec_helper"
require "vmc"
require "cli"
include BVT::Spec
include BVT::Harness

$:.unshift(File.join(File.dirname(__FILE__)))
require "rails_console_helper"

describe BVT::Spec::Simple::RailsConsole::RubyRails3 do
  include BVT::Spec::RailsConsoleHelper

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

  it "rails test console rake tasks with ruby 1.9" do
    app = create_push_app("rails_console_19_test_app")
    manifest = {}
    manifest["console"] = true
    app.update!(manifest)

    @console_cmd.restart(app.name)

    run_console(app.name)

    expected_results = ["irb():001:0> "]
    expected_results.should == @console_response

    send_cmd_and_verify("`rake routes`", ':action=>\"index\"')

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

    runtime = app.manifest['runtime']
    version = VCAP_BVT_SYSTEM_RUNTIMES[runtime][:version].split("p",2).first

    send_cmd_and_verify("`ruby --version`", "ruby #{version}")

    @console_cmd.close_console if @console_cmd
  end

  it "rails test console MySQL connection", :mysql=>true do
    app = create_push_app("rails_console_19_test_app")
    bind_service(MYSQL_MANIFEST, app)
    manifest = {}
    manifest["console"] = true
    app.update!(manifest)

    @console_cmd.restart(app.name)

    run_console(app.name)

    expected_results = ["irb():001:0> "]
    expected_results.should == @console_response

    runtime = app.manifest['runtime']
    version = VCAP_BVT_SYSTEM_RUNTIMES[runtime][:version].split("p",2).first


    send_cmd_and_verify("`ruby --version`", "ruby #{version}")

    send_cmd_and_verify("User.all", "[]")

    @console_cmd.send_console_command("user=User.new({:name=> 'Test', :email=>'test@test.com'})")

    send_cmd_and_verify("user.save!", "true")

    send_cmd_and_verify("User.all", "[#<User id: 1")
    @console_cmd.close_console if @console_cmd
  end

  it "rails test console Postgres connection", :postgresql=>true do
    app = create_push_app("rails_console_19_test_app")
    bind_service(POSTGRESQL_MANIFEST, app)
    manifest = {}
    manifest["console"] = true
    app.update!(manifest)

    @console_cmd.restart(app.name)

    run_console(app.name)

    expected_results = ["irb():001:0> "]
    expected_results.should == @console_response

    runtime = app.manifest['runtime']
    version = VCAP_BVT_SYSTEM_RUNTIMES[runtime][:version].split("p",2).first

    send_cmd_and_verify("`ruby --version`", "ruby #{version}")

    send_cmd_and_verify("User.all", "[]")

    @console_cmd.send_console_command("user=User.new({:name=> 'Test', :email=>'test@test.com'})")

    send_cmd_and_verify("user.save!", "true")

    send_cmd_and_verify("User.all", "[#<User id: 1")

    @console_cmd.close_console if @console_cmd
  end
end
