require "harness"
require "spec_helper"

describe BVT::Spec::ImageMagicKSupport::Java do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Deploy Java 7 Spring application that uses ImageMagick tools" do
    app = create_push_app("spring_imagemagick_java7")
    app.get_response(:get).body_str.should == "hello from imagemagick"
  end
end
