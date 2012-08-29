require "harness"
require "spec_helper"

include BVT::Spec

describe BVT::Spec::OrgSpace::Space do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:all) do
    @session.cleanup!
  end

  it "test create space" do
    spaces = @session.spaces

    space = @session.space("new-space", false)
    space.create
    spaces = @session.spaces
    match = false
    spaces.each{ |s|
      match = true if s.name == "new-space"
    }
    match.should == true
  end

end
