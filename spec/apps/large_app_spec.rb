require "harness"
require "spec_helper"
require "securerandom"

describe "Large Applications", big_app: true, runtime: true do
  before(:all) { @session = BVT::Harness::CFSession.new }
  after(:all) { @session.cleanup! }

  describe "app with a big file saved in the resource pool" do
    it "retrieves the file from the resource pool correctly" do
      app = make_app
      app.create!

      map_route(app)

      app.upload(asset("sinatra/large_file_app"))
      start_app_blocking(app)

      get_endpoint(app, "/").to_i.should > 64000
    end
  end

  describe "an app that has large files that are not in the resource pool" do
    it "successfully uploads the large app" do
      Dir.mktmpdir do |tmp_dir|
        FileUtils.cp_r(asset("sinatra/dora"), tmp_dir)

        app_path = File.join(tmp_dir, "dora")

        big_file = File.join(app_path, "big_file")

        # This creates a file ~ 200Mb + bundled gems after staging
        # Nginx config is currently set to 256Mb
        File.open(big_file, "w") do |f|
          4000.times do
            f.puts(SecureRandom.random_bytes(50000))
          end
        end

        app = make_app
        app.memory = 2048
        app.create!

        app.upload(app_path)
        start_app_blocking(app)

        assets = app.file("app")
        assets.should include("big_file")
      end
    end
  end
end
