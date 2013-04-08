require "yaml"
require "yajl"
require "harness"
require "digest/md5"
require "tempfile"

module BVT::Harness
  class Assets
    def sync
      downloads = get_assets_info

      if File.exist?(VCAP_BVT_ASSETS_PACKAGES_MANIFEST)
        locals = YAML.load_file(VCAP_BVT_ASSETS_PACKAGES_MANIFEST)['packages']
      else
        locals = []
      end

      puts "check local assets binaries"
      skipped = []

      if locals.any?
        total = locals.length
        locals.each_with_index do |item, index|
          downloads_index = downloads.index { |e| e['filename'] == item['filename'] }
          index_str = "[#{(index + 1).to_s}/#{total.to_s}]"

          if downloads_index
            if downloads[downloads_index]['md5'] == item['md5']
              puts "#{index_str}Skipped\t\t#{item['filename']}"
              downloads.delete_at(downloads_index)

              skipped << {
                'filename' => item['filename'],
                'md5' => item['md5'],
              }
            else
              puts "#{index_str}Need to update\t#{item['filename']}"
            end
          else
            puts "#{index_str}Remove\t\t#{item['filename']}"
            File.delete(File.join(VCAP_BVT_ASSETS_PACKAGES_HOME, item['filename']))
          end
        end
      end

      if downloads.any?
        puts "downloading assets binaries"

        unless Dir.exist?(VCAP_BVT_ASSETS_PACKAGES_HOME)
          Dir.mkdir(VCAP_BVT_ASSETS_PACKAGES_HOME)
        end

        total = downloads.length
        downloads.each_with_index do |item, index|
          index_str = "[#{(index + 1).to_s}/#{total.to_s}]"
          filepath = File.join(VCAP_BVT_ASSETS_PACKAGES_HOME, item['filename'])
          puts "#{index_str}downloading\t#{item['filename']}"

          download_binary(filepath)
          actual_md5 = check_md5(filepath)

          unless actual_md5 == item['md5']
            puts "#{index_str}fail to download\t\t#{item['filename']}.\n"+
                 "Might be caused by unstable network, please try again."
          end

          skipped << {
            'filename' => item['filename'],
            'md5' => actual_md5,
          }

          File.open(VCAP_BVT_ASSETS_PACKAGES_MANIFEST, "w") do |f|
            f.write(YAML.dump({'packages' => skipped}))
          end
        end
      end

      puts "sync assets binaries finished"
    end

    private

    def get_assets_info
      url = "#{VCAP_BVT_ASSETS_STORE_URL}/list"

      begin
        res = RestClient.get(url)
      rescue => e
        raise RuntimeError, <<-MSG
          Cannot connect to yeti assets storage server, #{url}
          Please check your network connection.
          Response: #{"#{res.code} #{res.to_str}" if res}
          Exception: #{e.inspect}\n#{e.backtrace}
        MSG
      end

      unless res.code == HTTP_RESPONSE_CODE::OK
        raise RuntimeError, <<-MSG
          Get remote file list failed, might be caused by unstable network.
          Response: #{"#{res.code} #{res.to_str}" if res}
        MSG
      end

      Yajl::Parser.new.parse(res.to_str)
    end

    def check_md5(filepath)
      Digest::MD5.hexdigest(File.read(filepath))
    end

    def download_binary(filepath)
      filename = File.basename(filepath)
      url = "#{VCAP_BVT_ASSETS_STORE_URL}/files/#{filename}"
      r = nil

      begin
        5.times do
          begin
            r = RestClient.get url
          rescue
            next
          end

          break if r.code == HTTP_RESPONSE_CODE::OK
          sleep(1)
        end
      rescue => e
        raise RuntimeError, "Download failed, might be caused by unstable network: #{e.inspect}"
      end

      if r && r.code == HTTP_RESPONSE_CODE::OK
        contents = r.to_str.chomp
        File.open(filepath, 'wb') { |f| f.write(contents) }
      else
        raise RuntimeError, <<-MSG
          Failed to download binary #{filename}:
          Response: #{"#{res.code} #{res.to_str}" if res}
        MSG
      end
    end
  end
end
