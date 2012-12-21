require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Simple::RubyGems::RubySinatra do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def verify_service(service_manifest, app, key)
    data = "#{service_manifest[:vendor]}#{key}"
    url = SERVICE_URL_MAPPING[service_manifest[:vendor]]
    app.get_response(:post, "/service/#{url}/#{key}", data)
    app.get_response(:get, "/service/#{url}/#{key}").to_str.should == data
  end

  def add_env(app,key,value)
     env = {"#{key}"=>"#{value}"}
     manifest = {}
     manifest['env'] = env
     manifest['state'] = 'STARTED'
     app.update!(manifest)
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

  it "sinatra test deploy app with git gems using ruby18" do
    app = create_push_app("git_gems_app_ruby18")
    app.stats.should_not == nil
    response = app.get_response(:get,"/")
    response.code.should == 200
    response.to_str.should == "hello from git"
  end

  it "sinatra test deploy app without specifying BUNDLE_WITHOUT" do
    app = create_push_app("sinatra_gem_groups")

    staging_log = app.file("logs/staging.log")
    staging_log.should_not include "Adding rspec-2.11.0.gem to app"
    bundle_config = app.file("app/.bundle/config")
    bundle_config.should include "BUNDLE_WITHOUT: test"
    response = app.get_response(:get,"/")
    response.code.should == 200
    response.to_str.should == "hello from sinatra"
  end

  it "sinatra test deploy app specifying BUNDLE_WITHOUT" do
    app = create_push_app("sinatra_gem_groups")
    app.stop
    add_env(app, "BUNDLE_WITHOUT", "development")
    app.start

    staging_log = app.file("logs/staging.log")
    staging_log.should include "Adding thor-0.15.4.gem to app"
    staging_log.should_not include "Adding rubyzip-0.9.9.gem to app"
    bundle_config = app.file("app/.bundle/config")
    bundle_config.should include "BUNDLE_WITHOUT: development"

    response = app.get_response(:get, "/")
    response.code.should == 200
    response.to_str.should == "hello from sinatra"

  end

  it "sinatra test deploy app setting BUNDLE_WITHOUT to multiple groups" do
    app = create_push_app("sinatra_gem_groups")
    app.stop
    add_env(app, "BUNDLE_WITHOUT", "development:test")
    app.start

    staging_log = app.file("logs/staging.log")
    staging_log.should_not include "Adding thor-0.15.4.gem to app"
    staging_log.should_not include "Adding rubyzip-0.9.9.gem to app"
    staging_log.should_not include "Adding rspec-2.11.0.gem to app"
    bundle_config = app.file("app/.bundle/config")
    bundle_config.should include "BUNDLE_WITHOUT: development:test"

    response = app.get_response(:get, "/")
    response.code.should == 200
    response.to_str.should == "hello from sinatra"

  end

  it "sinatra test deploy app setting BUNDLE_WITHOUT blank to override default" do
    app = create_push_app("sinatra_gem_groups")
    app.stop
    add_env(app, "BUNDLE_WITHOUT", "")
    app.start

    staging_log = app.file("logs/staging.log")
    staging_log.should include "Adding thor-0.15.4.gem to app"
    staging_log.should include "Adding rubyzip-0.9.9.gem to app"
    staging_log.should include "Adding rspec-2.11.0.gem to app"
    bundle_config = app.file("app/.bundle/config")
    bundle_config.should_not include "BUNDLE_WITHOUT"

    response = app.get_response(:get, "/")
    response.code.should == 200
    response.to_str.should == "hello from sinatra"

  end

  it "sinatra test deploy app with Gemfile.lock containing Windows versions", :mysql=>true, :postgresql=>true do
    app = create_push_app("sinatra_windows_gemfile")
    staging_log = app.file("logs/staging.log")
    staging_log.should_not include "Adding yajl-ruby-0.8.3.gem to app"
    staging_log.should include "Adding mysql2-0.3.11.gem to app"
    staging_log.should include "Adding pg-0.14.0.gem to app"

    bind_service(MYSQL_MANIFEST, app)
    verify_service(MYSQL_MANIFEST, app, "abc")
    bind_service(POSTGRESQL_MANIFEST, app)
    verify_service(POSTGRESQL_MANIFEST, app, "abc")

  end

  it "sinatra test deploy app containing gems specifying a ruby platform" do
    app = create_push_app("sinatra_gem_groups")
    staging_log = app.file("logs/staging.log")
    staging_log.should include "Adding uglifier-1.2.6.gem to app"
    staging_log.should_not include "Adding yajl-ruby-0.8.3.gem to app"

    response = app.get_response(:get, "/")
    response.code.should == 200
    response.to_str.should == "hello from sinatra"
  end


end
