require "harness"
require "spec_helper"

include BVT::Spec

describe BVT::Spec::OrgSpace::Space do

  before(:all) do
    @session = BVT::Harness::CFSession.new
    pending("cloud controller v1 API does not support org/space") unless @session.v2?
  end

  after(:all) do
    @session.cleanup!("all")
  end

  it "test create space" do
    spaces = @session.spaces

    spaces.each{|s| s.delete(true) if s.name=='new-space'}
    space = @session.space("new-space", false)
    space.create
    spaces = @session.spaces
    match = false
    spaces.each{ |s|
      match = true if s.name == "new-space"
    }
    match.should == true

    space.delete
  end

  it "test switch space" do
    spaces = @session.spaces

    spaces.each{|s| s.delete(true) if s.name=='switch-space'}

    @space = @session.space("switch-space", false)
    @space.create

    @session.select_org_and_space("","switch-space")

    app = create_push_app("simple_app")

    space = @session.current_space
    space.name.should == "switch-space"

    app = space.apps[0]
    app.name.should =~ /simple_app/

    @space.delete(true)
  end

end
