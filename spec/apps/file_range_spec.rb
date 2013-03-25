require "harness"
require "spec_helper"
require "rest-client"
include BVT::Spec

describe "Simple::FileRange" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
    pending("File range content feature is only available on multi-node cloud foundry environment," +
                " is not available on dev_setup") if @session.TARGET =~ /\.vcap\.me$/
  end

  after(:each) do
    @session.cleanup!
  end

  FILE_NAME = "foo.rb"

  it "should get back the final 10 bytes of the file" do

    @app = create_push_app("simple_app")
    @app.stats.should_not == nil

    range = "-10"
    num_bytes = 10
    @file_contents = File.read("#{@app.manifest['path']}/#{FILE_NAME}")
    url = "#{@session.TARGET}/apps/#{@app.name}/instances/0/files/app/#{FILE_NAME}"
    hdrs = {"AUTHORIZATION" => @session.token.auth_header, "Range" => "bytes=#{range}"}

    resp = RestClient.get(url, hdrs)
    resp.should_not == nil
    resp.body.should == @file_contents.slice(@file_contents.size - num_bytes, num_bytes)

  end

  it "should get back the final 224 bytes of the file" do

    @app = create_push_app("simple_app")
    @app.stats.should_not == nil

    range = "10-"
    num_bytes = 10
    @file_contents = File.read("#{@app.manifest['path']}/#{FILE_NAME}")
    url = "#{@session.TARGET}/apps/#{@app.name}/instances/0/files/app/#{FILE_NAME}"
    hdrs = {"AUTHORIZATION" => @session.token.auth_header, "Range" => "bytes=#{range}"}

    resp = RestClient.get(url, hdrs)
    resp.should_not == nil
    resp.body.should == @file_contents.slice(num_bytes, @file_contents.size)

  end

  it "should get back bytes 10-20 of the file" do

    @app = create_push_app("simple_app")
    @app.stats.should_not == nil

    range = "10-20"
    start = 10
    fin = 20
    num_bytes = fin - start + 1
    @file_contents = File.read("#{@app.manifest['path']}/#{FILE_NAME}")
    url = "#{@session.TARGET}/apps/#{@app.name}/instances/0/files/app/#{FILE_NAME}"
    hdrs = {"AUTHORIZATION" => @session.token.auth_header, "Range" => "bytes=#{range}"}

    resp = RestClient.get(url, hdrs)
    resp.should_not == nil
    resp.body.should == @file_contents.slice(start, num_bytes)

  end
end
