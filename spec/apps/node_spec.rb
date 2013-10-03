require "harness"
require "spec_helper"
include BVT::Spec

describe "Node", :runtime => true do
  before(:all) { @session = BVT::Harness::CFSession.new }

  def self.it_supports_basics(version, opts={})
    it "starts the app successfully" do
      res = app.get_response(:get, "/node_version")
      res.to_str.should start_with("v#{version}.")
    end

    it "supports git modules" do
      # The only to make sure that semver came from git (via npm)
      # is to check npm's _git-remotes internal dir.
      # (Older npm versions do not create _git-remotes)
      if opts[:skip_git_remotes]
        package_json = app.file("app/package.json")
        package_json.should include %q{"semver": "git://github.com}
      else
        files = app.files("app/.npm/_git-remotes").flatten
        files.should include "git-github-com-isaacs-node-semver-git-6952f3ca/"
      end

      res = app.get_response(:get, "/git_module")
      res.to_str.should == "ok"
    end

    it "supports native extensions via node-gyp" do
      log = app.staging_log
      log.should include "CXX(target) Release/obj.target/bcrypt_lib/src/blowfish.o"

      res = app.get_response(:get, "/native_ext")
      res.to_str.should == "ok"
    end
  end

  describe "node 0.6" do
    with_app "node0_6"
    it_supports_basics "0.6", :skip_git_remotes => true
  end

  describe "node 0.8" do
    with_app "node0_8"
    it_supports_basics "0.8"
  end

  describe "node 0.10" do
    with_app "node0_10"
    it_supports_basics "0.10"
  end
end
