require "harness"
require "spec_helper"

include BVT::Spec

describe "Simple::Space" do

  before do
    @session = BVT::Harness::CFSession.new
    pending("cloud controller v1 API does not support org/space") unless @session.v2?
  end

  after do
    @session.client.spaces.each do |space|
      space.apps.each do |app|
        app.service_bindings.each(&:delete!)
      end
    end
    @session.cleanup!("all")
  end

  let(:space_name) { "space#{rand(2**32).to_s(36)}" }

  it "test create space" do
    spaces = @session.spaces

    spaces.each { |s| s.delete(true) if s.name == space_name }
    space = @session.space(space_name, false)
    space.create
    spaces = @session.spaces
    match = false
    spaces.each do |s|
      match = true if s.name == space_name
    end
    match.should == true

    space.delete
  end

  it "test switch space" do
    use_space(space_name)

    app = create_push_app("simple_app")

    space = @session.current_space
    space.name.should == space_name

    app = space.apps[0]
    app.name.should =~ /simple_app/

    app.routes.each(&:delete!)
    @space.delete(true)
  end

  it "test create and delete app/route in space" do
    use_space(space_name)

    @app = create_push_app("simple_app")

    space = @session.current_space
    app = space.apps[0]
    app.name.should =~ /simple_app/

    route = app.routes[0]
    domain = space.domains[0].name
    route.name.should =~ /simple-app.#{domain}/

    @app.urls { |url| @app.unmap(url, :delete => true) }

    @app.delete
    space.apps.should == []

    @session.client.routes.should == []

    @space.delete(true)
  end

  def use_space(space_name)
    spaces = @session.spaces

    spaces.each { |s| s.delete(true) if s.name==space_name }
    @space = @session.space(space_name, false)
    @space.create

    @session.select_org_and_space("", space_name)
  end

end
