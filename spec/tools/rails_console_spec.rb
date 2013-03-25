require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Harness
include BVT::Harness::ConsoleHelpers


describe "Tools::RailsConsole" do

  before(:each) do
    @session = BVT::Harness::CFSession.new
    @client = @session.client
  end

  after(:each) do
    @session.cleanup!
  end

  def cfoundry_app(app)
    apps = @client.apps
    apps.find{ |a| a.name == app.name}
  end

  xit "rails test console" do
    app = cfoundry_app(create_push_app("rails_console_test_app", nil, nil, [POSTGRESQL_MANIFEST]))
    @console = init_console(@client, app)

    response = @console.send_console_command('app.class')
    match = false
    response.each{ |res|
      match = true if res =~ /#{Regexp.escape("ActionDispatch::Integration::Session")}/
    }
    match.should == true
  end

  xit "rails test console stdout redirect" do
    app = cfoundry_app(create_push_app("rails_console_test_app", nil, nil, [POSTGRESQL_MANIFEST]))
    @console = init_console(@client, app)

    response = @console.send_console_command("puts 'hi'")
    expect = ("puts 'hi',hi,=> nil,irb():002:0> ").split(",")
    response.should == expect
  end

  xit "rails test console rake task" do
    app = cfoundry_app(create_push_app("rails_console_test_app", nil, nil,  [POSTGRESQL_MANIFEST]))
    @console = init_console(@client, app)

    response = @console.send_console_command("`rake routes`")
    match = false
    response.each do |res|
      match = true if res =~ /#{Regexp.escape(':action=>\"hello\"')}/
    end
    match.should == true
  end

  xit "Rails Console runs tasks with correct ruby version in path" do
    app = cfoundry_app(create_push_app("rails_console_test_app", nil, nil,  [POSTGRESQL_MANIFEST]))
    @console = init_console(@client, app)

    response = @console.send_console_command("`ruby --version`")
    match = false
    response.each do |res|
      match = true if res =~ /#{Regexp.escape("ruby 1.9.2")}/
    end
    match.should == true
  end


  xit "rails test console MySQL connection" do
    app = cfoundry_app(create_push_app("rails_console_19_test_app", nil, nil, [MYSQL_MANIFEST]))
    @console = init_console(@client, app)

    response = @console.send_console_command("User.all")
    match = false
    response.each{ |res|
      match = true if res =~ /#{Regexp.escape("[]")}/
    }
    match.should == true

    @console.send_console_command("user=User.new({:name=> 'Test', :email=>'test@test.com'})")

    response = @console.send_console_command("user.save!")
    match = false
    response.each{ |res|
      match = true if res =~ /#{Regexp.escape("true")}/
    }
    match.should == true

    response = @console.send_console_command("User.all")
    match = false
    response.each{ |res|
      match = true if res =~ /#{Regexp.escape('[#<User id: 1')}/
    }
    match.should == true


  end

  xit "rails test console Postgres connection" do
    app = cfoundry_app(create_push_app("rails_console_19_test_app", nil, nil, [POSTGRESQL_MANIFEST]))
    @console = init_console(@client, app)

    response = @console.send_console_command("User.all")
    match = false
    response.each{ |res|
      match = true if res =~ /#{Regexp.escape("[]")}/
    }
    match.should == true

    @console.send_console_command("user=User.new({:name=> 'Test', :email=>'test@test.com'})")

    response = @console.send_console_command("user.save!")
    match = false
    response.each{ |res|
      match = true if res =~ /#{Regexp.escape("true")}/
    }
    match.should == true

    response = @console.send_console_command("User.all")
    match = false
    response.each{ |res|
      match = true if res =~ /#{Regexp.escape('[#<User id: 1')}/
    }
    match.should == true

  end
end
