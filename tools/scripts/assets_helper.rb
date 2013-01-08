$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))

require "yaml"
require "interact"
require "tools"
require "mongo"
require "yajl"
require "digest/md5"
require "harness"

module Tools
  module AssetsHelper
    include Interactive, BVT::Harness::ColorHelpers, BVT::Harness::HTTP_RESPONSE_CODE

    def update_local_hash(update_list)
      if Dir.exist?(VCAP_BVT_ASSETS_PACKAGES_HOME)
        unless update_list.empty?
          File.open(VCAP_BVT_ASSETS_PACKAGES_MANIFEST, "w") do |f|
            f.write YAML.dump(Hash['packages' => update_list])
          end
        end
      end
    end

    VCAP_BVT_GRIDFS_COLLECTION = 'fs.files'
    def upload_assets
      datastore_config = YAML.load_file(VCAP_BVT_ASSETS_DATASTORE_CONFIG)
      assets = list_binaries(datastore_config[:list])

      puts "check assets storage server"
      uploads = YAML.load_file(VCAP_BVT_ASSETS_PACKAGES_MANIFEST)['packages']
      total = assets.length
      assets.each_with_index do |row, index|
        uploads_index = uploads.index {|item| item['filename'] == row['filename']}
        index_str = "[#{(index + 1).to_s}/#{total.to_s}]"
        if uploads_index
          if uploads[uploads_index]['md5'] == row['md5']
            puts green("#{index_str}Skipped\t\t#{row['filename']}")
            uploads.delete_at(uploads_index)
          else
            puts yellow("#{index_str}Need to update\t#{row['filename']}")
          end
        else
          puts red("#{index_str}Removed\t\t#{row['filename']}")
          delete_binary(datastore_config[:delete], row['filename'])
        end
      end

      puts "\nUploading assets binaries"
      unless uploads.empty?
        total = uploads.length
        uploads.each_with_index do |item, index|
          filepath = File.join(VCAP_BVT_ASSETS_PACKAGES_HOME, item['filename'])
          file = File.open(filepath)
          index_str = "[#{(index + 1).to_s}/#{total.to_s}]"
          puts yellow("#{index_str}Uploading\t#{item['filename']}")
          post_binary(datastore_config[:upload], filepath, item['md5'])
        end
      end
      puts green("uploading assets binaries finished")
    end

    def check_md5(filepath)
      Digest::MD5.hexdigest(File.read(filepath))
    end

    private

    def list_binaries(url)
      begin
        result = RestClient.get url
      rescue
        raise RuntimeError,
              red("Cannot connect to yeti blobs storage server, #{url}\n" +
                      "Please check your network connection.")
      end

      if result.code == OK
        parser = Yajl::Parser.new
        return parser.parse(result.to_str)
      end
    end

    def delete_binary(url, filename)
      begin
        result = RestClient.delete "#{url}/#{filename}"
      rescue
        raise RuntimeError,
              red("Cannot connect to yeti blobs storage server, #{url}\n" +
                      "Please check your network connection.")
      end

      unless result.code == OK
        raise RuntimeError, "Fail to delete file #{filename}\nPlease rerun " +
            "'#{yellow("rake upload_assets")}' command."
      end
    end

    def post_binary(url, filepath, md5)
      filename = File.basename(filepath)
      begin
        resource = RestClient::Resource.new("#{url}?md5=#{md5}", :timeout => 600, :open_timeout => 600)
        result = resource.post :file => File.open(filepath, "rb")
      rescue
        raise RuntimeError,
              red("Cannot connect to yeti blobs storage server, #{url}\n" +
                      "Please check your network connection.")
      end

      unless result.code == OK
        raise RuntimeError, "Fail to post file #{filename}\nPlease rerun " +
            "'#{yellow("rake upload_assets")}' command."
      end
    end

    extend self
  end
end
