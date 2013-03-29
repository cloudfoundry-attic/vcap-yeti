require "harness"
require "spec_helper"
include BVT::Spec

describe "Ruby" do
  before(:all) { @session = BVT::Harness::CFSession.new }

  def self.it_supports_basics(version)
    it "starts the app successfully" do
      res = app.get_response(:get, "/ruby_version")
      res.to_str.should start_with(version)
    end

    it "supports git gems" do
      app.file("logs/staging_task.log").tap do |log|
        log.should match %r{Using cf .* git://github.com/cloudfoundry/cf.git}
      end
    end

    it "installs native extensions" do
      app.file("logs/staging_task.log").tap do |log|
        log.should include "Installing ffi"
      end
    end
  end

  describe "ruby 1.8" do
    with_app "ruby18"
    it_supports_basics "1.8.7"
  end

  describe "ruby 1.9" do
    with_app "ruby19"
    it_supports_basics "1.9"
  end

  describe "rails" do
    with_app "rails3"

    it "starts the app successfully" do
      res = app.get_response(:get, "/health")
      res.to_str.should == "ok"
    end
  end
end
