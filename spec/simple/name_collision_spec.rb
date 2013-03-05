require "harness"
require "spec_helper"
require "securerandom"
include BVT::Spec

describe "Simple::NameCollision" do
  let(:session) { BVT::Harness::CFSession.new }
  let(:cfoundry_app) { session.client.app }
  let(:prefix) { SecureRandom.hex(8) }
  let(:app_name) { "#{prefix}-simple_app" }

  before do
    pending if session.v1?
    cfoundry_app.name = app_name
    @yeti_app = App.new(cfoundry_app, session, nil)
    @yeti_app.load_manifest
  end

  after do
    session.cleanup!
  end

  def deploy_app_with_name(yeti_app, name)
    yeti_app.create_app(name, yeti_app.manifest['path'], nil, nil)
  end

  it "will not push two apps with the same name" do
    deploy_app_with_name(@yeti_app, app_name)
    expect { deploy_app_with_name(@yeti_app, app_name) }.to raise_error(RuntimeError, /CFoundry::AppNameTaken/)
  end

  it "will not push two apps whose names only differ in capitalization" do
    deploy_app_with_name(@yeti_app, app_name)
    expect { deploy_app_with_name(@yeti_app, app_name.upcase) }.to raise_error(RuntimeError, /CFoundry::AppNameTaken/)
  end
end
