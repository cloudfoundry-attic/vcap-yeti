require "harness"
require "spec_helper"
include BVT::Spec

describe "Admin Buildpacks" do
  before(:all) { @session = BVT::Harness::CFSession.new }
  after(:all) do
    @session.cleanup!
  end

  describe "admin uploads a buildpack" do
    def make_payload(zip_file_path)
      {
        :buildpack => UploadIO.new(File.expand_path(zip_file_path), 'application/zip'),
        :buildpack_path => File.basename(zip_file_path)}
    end

    after(:all) do
      if @buildpack_guid
        @admin_session.client.base.delete("/v2/buildpacks/#{@buildpack_guid}")
      end
    end

    def zip(zip_filename, dir)
      Dir.chdir(dir) do
        system("zip -r #{zip_filename} .")
      end
    end

    before(:all) do
      buildpack_name = "foo"
      buildpack_dir = File.expand_path("../../../assets/buildpacks/simple_buildpack", __FILE__)

      @tmpdir = Dir.mktmpdir
      zip_file_name = File.join(@tmpdir, "simple_buildpack.zip")
      zip(zip_file_name, buildpack_dir)

      @admin_session = BVT::Harness::CFSession.new(:admin => true)
      buildpack = JSON.parse(@admin_session.client.base.post("/v2/buildpacks", :payload => {:name => buildpack_name}.to_json))
      @buildpack_guid = buildpack.fetch('metadata').fetch('guid')

      @admin_session.client.base.post("/v2/buildpacks/#{@buildpack_guid}/bits", :payload => make_payload(File.expand_path(zip_file_name, @tmpdir)))
    end

    after(:all) do
      FileUtils.remove_entry @tmpdir
    end

    with_app "buildpack_test"

    it 'uses the uploaded buildpack' do
      app.get('/').should match "hi from a simple admin buildpack"
    end
  end
end
