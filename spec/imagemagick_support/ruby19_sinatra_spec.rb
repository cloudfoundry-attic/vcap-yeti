require "harness"
require "spec_helper"

describe BVT::Spec::ImageMagicKSupport::Ruby19Sinatra do
  include BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  it "Deploy application that uses RMagick" do
    begin
      app = create_push_app("sinatra_rmagick")
    rescue RuntimeError => e
      if e.to_s =~ /310: Staging failed: 'Staging task failed:/
        pending("imagemagick is not available on target environment: #{@session.TARGET}")
      end
    end

    app.get_response(:get).body_str.should == "hello from rmagick"
  end
end
