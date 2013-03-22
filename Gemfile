source "http://rubygems.org"

gem "rake"
gem "rspec"
gem "rspec_parallel", ">= 0.1.6"

gem "rest-client"
gem "mongo"

gem "bson_ext"
gem "yajl-ruby"
gem "nokogiri"

group :vcap do
  gem "interact"

  # Used to create users in CCNGUserHelper
  gem "cf-uaac", "= 1.3.3"
  gem "vcap_logging", ">= 1.0"

  # Specific version of cfoundry is needed to be
  # compatible with deps from cf-uaas. Update with care!
  gem "cfoundry", {
  	:github => "cloudfoundry/vmc-lib",
  	:ref => "e11ddf5d",
  	:submodules => true,
  }

  gem "tunnel-vmc-plugin", :github => "cloudfoundry/tunnel-vmc-plugin"
  gem "console-vmc-plugin", :github => "cloudfoundry/console-vmc-plugin"
end