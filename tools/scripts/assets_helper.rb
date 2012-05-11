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
    include Interactive, BVT::Harness::ColorHelpers

    def update_local_hash
      if Dir.exist?(VCAP_BVT_ASSETS_PACKAGES_HOME)
        skipped = []
        Dir.new(VCAP_BVT_ASSETS_PACKAGES_HOME).each {|d|
          if d.end_with?('.war') or d.end_with?('.jar')
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
      conn = Mongo::Connection.new(datastore_config['host'], datastore_config['port'])
      db = conn.db(datastore_config['dbname'])
      auth = db.authenticate(datastore_config['username'], datastore_config['password'])

      puts "check assets storage server"
      uploads = YAML.load_file(VCAP_BVT_ASSETS_PACKAGES_MANIFEST)['packages']
      grid = Mongo::Grid.new(db)
      if db.collection_names.include?(VCAP_BVT_GRIDFS_COLLECTION)
        coll = db[VCAP_BVT_GRIDFS_COLLECTION]
        total = coll.find.to_a.length
        coll.find.each_with_index do |row, index|
          uploads_index = uploads.index {|item| item['filename'] == row['filename']}
          index_str = "[#{(index + 1).to_s}/#{total.to_s}]"
          if uploads_index
            if uploads[uploads_index]['md5'] == row['md5']
              puts green("#{index_str}Skipped\t\t#{row['filename']}")
              uploads.delete_at(uploads_index)
            else
              puts yellow("#{index_str}Need to update\t#{row['filename']}")
              grid.delete(row['_id'])
            end
          else
            puts red("#{index_str}Removed\t\t#{row['filename']}")
            grid.delete(row['_id'])
          end
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
          grid.put(file, :filename => item['filename'], :safe => true)
        end
      end
      puts green("uploading assets binaries finished")
    end

    def check_md5(filepath)
      Digest::MD5.hexdigest(File.read(filepath))
    end

    extend self
  end
end
