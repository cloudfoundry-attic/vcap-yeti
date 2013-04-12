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

  it "test create and delete app/service in space" do
    use_space(space_name)

    create_push_app("simple_app", nil, nil, [MYSQL_MANIFEST])

    space = @session.current_space

    app = space.apps[0]
    app.name.should =~ /simple_app/
    service = space.service_instances[0]
    puts service.inspect
    service.name.should =~ /mysql/

    app.delete!
    space.apps.should == []
    service.delete!
    space.service_instances.should == []

    app.routes.each(&:delete!)
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
