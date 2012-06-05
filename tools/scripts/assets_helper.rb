$:.unshift(File.join(File.dirname(__FILE__), "../../lib"))

require "yaml"
require "interact"
require "tools"
require "curb"
require "mongo"
require "yajl"
require "digest/md5"
require "harness"

module Tools
  module AssetsHelper
    include Interactive, BVT::Harness::ColorHelpers, BVT::Harness::HTTP_RESPONSE_CODE

    def update_local_hash
      if Dir.exist?(VCAP_BVT_ASSETS_PACKAGES_HOME)
        skipped = []
        Dir.new(VCAP_BVT_ASSETS_PACKAGES_HOME).each {|d|
          if d.end_with?('.war') or d.end_with?('.zip')
            file_path = File.join(VCAP_BVT_ASSETS_PACKAGES_HOME, d)
            md5 = check_md5(file_path)
            skipped << Hash['filename' => d, 'md5' => md5]
          end
        }
        if skipped != []
          File.open(VCAP_BVT_ASSETS_PACKAGES_MANIFEST, "w") do |f|
            f.write YAML.dump(Hash['packages' => skipped])
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
      easy = Curl::Easy.new
      easy.url = url
      easy.resolve_mode = :ipv4
      easy.timeout = 10
      begin
        easy.http_get
      rescue Curl::Err::CurlError
        raise RuntimeError,
              red("Cannot connect to yeti blobs storage server, #{easy.url}\n" +
                      "Please check your network connection.")
      end

      if easy.response_code == OK
        parser = Yajl::Parser.new
        return parser.parse(easy.body_str)
      end
    end

    def delete_binary(url, filename)
      easy = Curl::Easy.new
      easy.url = "#{url}/#{filename}"
      easy.resolve_mode = :ipv4
      easy.timeout = 10
      begin
        easy.http_delete
      rescue Curl::Err::CurlError
        raise RuntimeError,
              red("Cannot connect to yeti blobs storage server, #{easy.url}\n" +
                      "Please check your network connection.")
      end

      unless easy.response_code == OK
        raise RuntimeError, "Fail to delete file #{filename}\nPlease rerun " +
            "'#{yellow("rake upload_assets")}' command."
      end
    end

    def post_binary(url, filepath, md5)
      filename = File.basename(filepath)
      easy = Curl::Easy.new
      easy.url = "#{url}?md5=#{md5}"
      easy.resolve_mode = :ipv4
      easy.timeout = 60 * 10

      post_data = Curl::PostField.file('file', filepath)
      easy.multipart_form_post = true

      begin
        easy.http_post(post_data)
      rescue Curl::Err::CurlError
        raise RuntimeError,
              red("Cannot connect to yeti blobs storage server, #{easy.url}\n" +
                      "Please check your network connection.")
      end

      unless easy.response_code == OK
        raise RuntimeError, "Fail to post file #{filename}\nPlease rerun " +
            "'#{yellow("rake upload_assets")}' command."
      end
    end

    extend self
  end
end
