source "http://rubygems.org"

gem "rake"
gem "rspec"
gem "rspec_parallel", ">= 0.1.6"

gem "rest-client"
gem "mongo"

gem "bson_ext"
gem "yajl-ruby"
gem "nokogiri"

gem "fuubar"
gem "progressbar", "~> 0.11.0"

group :vcap do
  gem "interact"
  gem "caldecott"

  gem "vcap_logging", ">= 1.0"
  gem "cf-uaac", "= 1.3.3"
  gem "cfoundry", :github => "cloudfoundry/vmc-lib", :submodules => true

  git "git://github.com/cloudfoundry/vmc-plugins.git" do
    gem "tunnel-vmc-plugin"
    gem "console-vmc-plugin"
  end
end