source "http://rubygems.org"

gem "rake"
gem "rspec"
gem "parallel_tests"

gem "rest-client"
gem "mongo"

gem "bson_ext"
gem "yajl-ruby"
gem "nokogiri"

group :vcap do
  gem "vcap_logging", ">= 1.0"

  gem "cfoundry", {
    :github => "cloudfoundry/cfoundry",
    :submodules => true,
  }

  gem "tunnel-cf-plugin", :github => "cloudfoundry/tunnel-cf-plugin"
  gem "console-cf-plugin", :github => "cloudfoundry/console-cf-plugin"
end
