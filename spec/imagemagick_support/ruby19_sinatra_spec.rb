require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::ImageMagicKSupport::Ruby19Sinatra do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Deploy Ruby application that uses RMagick and ImageMagick tools" do
    app = create_push_app("sinatra_imagemagick")
    app.get_response(:get).body_str.should == "hello from imagemagick"
  end
end
