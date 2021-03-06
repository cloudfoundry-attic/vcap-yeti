require "harness"
require "spec_helper"
require "rest-client"

describe "Simple::FileRange", :runtime => true do
  before(:all) do
    @session = BVT::Harness::CFSession.new

    if @session.api_endpoint =~ /\.vcap\.me$/
      pending("File range content feature is only available on multi-node cloud foundry environment," +
                  " is not available on dev_setup")
    end

    @app = create_push_app("simple_app")
  end

  after(:all) do
    @session.cleanup!
  end

  let(:filename) { "foo.rb" }

  it "should get back the final 10 bytes of the file" do
    range = "-10"
    num_bytes = 10

    file_contents = File.read("#{@app.manifest['path']}/#{filename}")
    resp = @app.get_file("app/#{filename}", "Range" => "bytes=#{range}")

    resp.should_not be_nil
    resp.body.should == file_contents.slice(file_contents.size - num_bytes, num_bytes)
  end

  it "should get back the final 224 bytes of the file" do
    range = "10-"
    num_bytes = 10

    file_contents = File.read("#{@app.manifest['path']}/#{filename}")
    resp = @app.get_file("app/#{filename}", "Range" => "bytes=#{range}")

    resp.should_not be_nil
    resp.body.should == file_contents.slice(num_bytes, file_contents.size)
  end

  it "should get back bytes 10-20 of the file" do
    range = "10-20"
    num_bytes = 11

    file_contents = File.read("#{@app.manifest['path']}/#{filename}")
    resp = @app.get_file("app/#{filename}", "Range" => "bytes=#{range}")

    resp.should_not be_nil
    resp.body.should == file_contents.slice(10, num_bytes)
  end
end
