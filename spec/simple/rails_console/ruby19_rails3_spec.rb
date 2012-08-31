require "harness"
require "spec_helper"
require "vmc"
require "cli"
include BVT::Spec
include BVT::Harness

$:.unshift(File.join(File.dirname(__FILE__)))
require "rails_console_helper"

describe BVT::Spec::Simple::RailsConsole::Ruby19Rails3 do
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

    send_cmd_and_verify("`ruby --version`", "ruby 1.9")

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


    send_cmd_and_verify("`ruby --version`", "ruby 1.9")

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

    send_cmd_and_verify("`ruby --version`", "ruby 1.9")

    send_cmd_and_verify("User.all", "[]")

    @console_cmd.send_console_command("user=User.new({:name=> 'Test', :email=>'test@test.com'})")

    send_cmd_and_verify("user.save!", "true")

    send_cmd_and_verify("User.all", "[#<User id: 1")

    @console_cmd.close_console if @console_cmd
  end
end
