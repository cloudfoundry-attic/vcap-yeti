require "harness"
require "spec_helper"

include BVT::Spec

describe BVT::Spec::OrgSpace::Space do

  before(:each) do
    @session = BVT::Harness::CFSession.new
    pending("cloud controller v1 API does not support org/space") unless @session.v2?
  end

  after(:each) do
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
    use_space("switch_space")

    app = create_push_app("simple_app")

    space = @session.current_space
    space.name.should == "switch_space"

    app = space.apps[0]
    app.name.should =~ /simple_app/

    app.routes.each(&:delete!)
    @space.delete(true)
  end

  it "test create and delete app/service in space" do
    use_space("new_space")

    app = create_push_app("simple_app")
    bind_service(MYSQL_MANIFEST, app)

    space = @session.current_space

    app = space.apps[0]
    app.name.should =~ /simple_app/
    service = space.service_instances[0]
    service.name.should =~ /mysql/

    app.delete!
    space.apps.should == []
    service.delete!
    space.service_instances.should == []

    app.routes.each(&:delete!)
    @space.delete(true)
  end

  it "test create and delete app/route in space" do
    pending "This test needs to be implemented based on correct expectations"
    use_space("new_space")

    @app = create_push_app("simple_app")

    space = @session.current_space
    app = space.apps[0]
    app.name.should =~ /simple_app/

    route = app.routes[0]
    domain = space.domains[0].name
    route.name.should =~ /simple-app.#{domain}/

    @app.delete
    space.apps.should == []
    # This is NOT the correct behavior.  Deletion of an app does not cause
    # associated routes to be deleted.  This is by design.  Otherwise,
    # someone can route snipe.
    #
    # If this test is supposed to be testing route deletion, it needs to
    # actually delete routes.
    # @session.client.routes.should == []

    @space.delete(true)
  end

  def use_space(space_name)
    spaces = @session.spaces

    spaces.each{|s| s.delete(true) if s.name==space_name}
    @space = @session.space(space_name, false)
    @space.create

    @session.select_org_and_space("",space_name)
  end

end
