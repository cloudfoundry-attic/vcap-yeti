#only load ci reports task on ci box
if ENV.has_key?("CI_REPORTS")
  require "ci/reporter/rake/rspec_loader"
end
