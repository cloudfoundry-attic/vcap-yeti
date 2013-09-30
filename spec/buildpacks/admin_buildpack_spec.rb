require "harness"
require "spec_helper"
include BVT::Spec

describe "Admin Buildpacks" do
  before(:all) do
    @session = BVT::Harness::CFSession.new
    @tmpdir = Dir.mktmpdir
    @admin_session = BVT::Harness::CFSession.new(:admin => true)
    @buildpack_guid = upload_buildpack("simple_buildpack")
  end

  after(:all) do
    if @buildpack_guid
      @admin_session.client.base.delete("/v2/buildpacks/#{@buildpack_guid}")
    end
    FileUtils.remove_entry @tmpdir
    @session.cleanup!
  end

  describe "admin uploads a buildpack" do
    with_app "buildpack_test"

    it 'uses the uploaded buildpack' do
      app.get('/').should match "hi from a simple admin buildpack"
    end
  end

  describe "specifying an admin buildpack with --buildpack" do
    it "doesn't use any admin buildpack except the one whose name was specified" do
      begin
        @buildpack_guid_never_detects = upload_buildpack("another_buildpack")
        app = create_push_app("specific_buildpack_test")
        app.get('/').should_not match "hi from a simple admin buildpack"
        app.get('/').should match "hi from another buildpack"
      ensure
        @admin_session.client.base.delete("/v2/buildpacks/#{@buildpack_guid_never_detects}")
      end
    end
  end

  def delete_buildpack_if_exists(buildpack_name, existing_buildpacks)
    buildpack_with_same_name = existing_buildpacks["resources"].detect do |resource|
      resource["entity"]["name"] == buildpack_name
    end

    if buildpack_with_same_name
      @admin_session.client.base.delete(buildpack_with_same_name["metadata"]["url"])
    end
  end

  def upload_buildpack (buildpack_name)
    buildpack_dir = File.expand_path("../../../assets/buildpacks/#{buildpack_name}", __FILE__)

    zip_file_name = File.join(@tmpdir, "#{buildpack_name}.zip")
    zip(zip_file_name, buildpack_dir)

    existing_buildpacks = JSON.parse @admin_session.client.base.get("/v2/buildpacks")

    delete_buildpack_if_exists(buildpack_name, existing_buildpacks)

    buildpack = JSON.parse(@admin_session.client.base.post("/v2/buildpacks", :payload => {:name => buildpack_name}.to_json))
    guid = buildpack.fetch('metadata').fetch('guid')

    @admin_session.client.base.post("/v2/buildpacks/#{guid}/bits", :payload => make_payload(File.expand_path(zip_file_name, @tmpdir)))
    guid
  end

  def zip(zip_filename, dir)
    Dir.chdir(dir) do
      system("zip -r #{zip_filename} .")
    end
  end

  def make_payload(zip_file_path)
    {
      :buildpack => UploadIO.new(File.expand_path(zip_file_path), 'application/zip'),
      :buildpack_path => File.basename(zip_file_path)}
  end
end
