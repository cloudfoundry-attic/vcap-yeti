require "harness"
require "spec_helper"
include BVT::Spec

describe "Tools::ImageMagick" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Deploy Java 6 Spring application that uses ImageMagick tools" do
    app = create_push_app("spring_imagemagick_java6")
    app.get_response(:get).to_str.should == "hello from imagemagick"
  end

  it "Deploy Node.js application that uses ImageMagick tools" do
    app = create_push_app("node_imagemagick")
    app.get_response(:get).to_str.should == "hello from imagemagick"
  end

  it "Deploy Ruby application that uses RMagick and ImageMagick tools" do
    app = create_push_app("sinatra_imagemagick")
    app.get_response(:get).to_str.should == "hello from imagemagick"
  end
end
