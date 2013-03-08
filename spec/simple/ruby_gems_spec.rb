require "harness"
require "spec_helper"
include BVT::Spec

describe "Simple::RubyGems" do

  before(:all) { @session = BVT::Harness::CFSession.new }

  after do
    show_crashlogs
    @session.cleanup!
  end

  def verify_service(service_manifest, app, key)
    data = "#{service_manifest[:vendor]}#{key}"
    url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
    app.get_response(:post, "/service/#{url}/#{key}", data)
    app.get_response(:get, "/service/#{url}/#{key}").to_str.should == data
  end

  def add_env(app,key,value)
    app.env[key] = value
    app.update!
    app.start
  end

  it "access my application root and see hello from sinatra", :p1 => true do
    app = create_push_app("broken_gem_app")
    app.stats.should_not == nil
    app.get_response(:get).should_not == nil
    app.get_response(:get).to_str.should_not == nil
    app.get_response(:get).to_str.should == "hello from sinatra"
  end

  it "sinatra test deploy app with git gems using ruby19" do
    app = create_push_app("git_gems_app_ruby19")
    app.stats.should_not == nil
    response = app.get_response(:get,"/")
    response.code.should == 200
    response.to_str.should == "hello from git"
  end

  it "sinatra test deploy app with git gems using ruby18", :slow => true do
    app = create_push_app("git_gems_app_ruby18")
    app.stats.should_not == nil
    response = app.get_response(:get,"/")
    response.code.should == 200
    response.to_str.should == "hello from git"
  end

  it "sinatra test deploy app with Gemfile.lock containing Windows versions", :mysql=>true, :postgresql=>true do
    app = create_push_app("sinatra_windows_gemfile", nil, nil, [MYSQL_MANIFEST, POSTGRESQL_MANIFEST])
    staging_log = app.file("logs/staging_task.log")
    staging_log.should_not match "Installing yajl-ruby"
    staging_log.should include "Installing mysql2"
    staging_log.should include "Installing pg"

    verify_service(MYSQL_MANIFEST, app, "abc")
    verify_service(POSTGRESQL_MANIFEST, app, "abc")
  end

  it "sinatra test deploy app containing gems specifying a ruby platform" do
    app = create_push_app("sinatra_gem_groups")
    staging_log = app.file("logs/staging_task.log")
    staging_log.should include "Installing uglifier (1.2.6)"
    staging_log.should_not include "Installing yajl-ruby (0.8.3)"

    response = app.get_response(:get, "/")
    response.code.should == 200
    response.to_str.should == "hello from sinatra"
  end
end
