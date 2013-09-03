require "harness"
require "spec_helper"
require "securerandom"
include BVT::Spec

describe "Large Applications" do
  before(:all) { @session = BVT::Harness::CFSession.new }
  after(:all) do
    @session.cleanup!
  end

  describe "app with a big file saved in the resource pool" do
    with_app "large_file", :debug => "sometimes"

    it 'should retrieve the file from the resource pool correctly' do
      Integer(app.get_response(:get, '/').body).should > 64000
    end
  end

  describe "an app that has large files that are not in the resource pool" do
    it "successfully uploads the large app" do
      Dir.mktmpdir do |tmp_dir|
        FileUtils.cp_r(File.expand_path("../../../assets/sinatra/hello_vcap", __FILE__), tmp_dir)
        app_path = File.join(tmp_dir, "hello_vcap")
        big_file = File.join(app_path, "assets", "big_file")

        # This creates a file ~ 200Mb + bundled gems after staging
        # Nginx config is currently set to 256Mb
        File.open(big_file, "w") do |f|
          4000.times do
            f.puts(SecureRandom.random_bytes(50000))
          end
        end

        BVT::Harness::VCAP_BVT_APP_ASSETS["big_random_app"] = {
          "path" => app_path,
          "instances" => 1,
          "memory" => 2048,
          "command" => "bundle exec ruby foo.rb -p $VCAP_APP_PORT"
        }

        app = create_push_app("big_random_app")
        assets = app.file("/app/assets/")
        assets.should include("big_file")
      end
    end
  end
end
