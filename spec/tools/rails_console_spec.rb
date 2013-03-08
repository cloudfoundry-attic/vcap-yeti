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
    show_crashlogs
    @session.cleanup!
  end

  def open_console(app)
    apps = @client.apps
    app = apps.find{ |a| a.name == app.name}
    app.console = true
    app.restart!
    app
  end

  it "rails test console", :slow => true, :p1 => true do
    app = create_push_app("rails_console_test_app", nil, nil, [POSTGRESQL_MANIFEST])
    app = open_console(app)

    sleep 1

    @console = init_console(@client, app)

    response = @console.send_console_command('app.class')
    match = false
    response.each{ |res|
      match = true if res =~ /#{Regexp.escape("ActionDispatch::Integration::Session")}/
    }
    match.should == true
  end

  it "rails test console stdout redirect", :slow => true do
    app = create_push_app("rails_console_test_app", nil, nil, [POSTGRESQL_MANIFEST])

    app = open_console(app)

    sleep 1

    @console = init_console(@client, app)

    response = @console.send_console_command("puts 'hi'")
    expect = ("puts 'hi',hi,=> nil,irb():002:0> ").split(",")
    response.should == expect
  end

  it "rails test console rake task", :slow => true do
    app = create_push_app("rails_console_test_app", nil, nil,  [POSTGRESQL_MANIFEST])

    app = open_console(app)

    sleep 1

    @console = init_console(@client, app)

    response = @console.send_console_command("`rake routes`")
    match = false
    response.each do |res|
      match = true if res =~ /#{Regexp.escape(':action=>\"hello\"')}/
    end
    match.should == true
  end

  it "Rails Console runs tasks with correct ruby version in path", :slow => true do

    app = create_push_app("rails_console_test_app", nil, nil,  [POSTGRESQL_MANIFEST])
    app = open_console(app)

    sleep 1

    @console = init_console(@client, app)

    response = @console.send_console_command("`ruby --version`")
    match = false
    response.each do |res|
      match = true if res =~ /#{Regexp.escape("ruby 1.9.2")}/
    end
    match.should == true
  end


  it "rails test console MySQL connection", :slow => true, :mysql=>true do
    app = create_push_app("rails_console_19_test_app", nil, nil, [MYSQL_MANIFEST])
    app = open_console(app)
    sleep 1

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

  it "rails test console Postgres connection", :slow => true, :postgresql=>true do
    app = create_push_app("rails_console_19_test_app", nil, nil, [POSTGRESQL_MANIFEST])
    app = open_console(app)
    sleep 1

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
