require "harness"
require "spec_helper"
include BVT::Spec

describe "Application name collision" do
  let(:session) { BVT::Harness::CFSession.new }
  let(:cfoundry_app) { session.client.app }

  before do
    cfoundry_app.name = "prefix-simple_app"
    @yeti_app = App.new(cfoundry_app, session, nil)
    @yeti_app.load_manifest

    @yeti_app.check_runtime(@yeti_app.manifest['runtime'])
    @yeti_app.check_framework(@yeti_app.manifest['framework'])
  end

  after do
    session.cleanup!
  end

  def deploy_app_with_name(yeti_app, name)
    yeti_app.create_app(name, yeti_app.manifest['path'], nil, nil)
  end

  it "will not push two apps with the same name" do
    deploy_app_with_name(@yeti_app, "prefix-simple_app")
    expect { deploy_app_with_name(@yeti_app, "prefix-simple_app") }.to raise_error(RuntimeError, /CFoundry::AppNameTaken/)
  end

  it "will not push two apps whose names only differ in capitalization" do
    deploy_app_with_name(@yeti_app, "prefix-simple_app")
    expect { deploy_app_with_name(@yeti_app, "PREFIX-SIMPLE_APP") }.to raise_error(RuntimeError, /CFoundry::AppNameTaken/)
  end
end
