#!/usr/bin/env ruby
require "rubygems"
require "cfoundry"

client = CFoundry::Client.get(ENV["VCAP_BVT_API_ENDPOINT"])
client.login(:username => ENV["VCAP_BVT_ADMIN_USER"], :password => ENV["VCAP_BVT_ADMIN_USER_PASSWD"])

puts "Going hunting..."

all_orgs = client.organizations :depth => 0
useless_orgs = all_orgs.select do |org|
  org.name =~ /(^org(anization)?-|#{ENV['VCAP_BVT_ORG_NAMESPACE']}_?yeti_test_org)/
end

puts "Targets acquired:"
useless_orgs.each do |org|
  puts "  #{org.name}"
end

puts ""
puts "Nuke'em?"
print "> "
ans = gets

unless ans.downcase.start_with?("y")
  puts "ABORT"
  exit(1)
end

useless_orgs.each do |org|
  puts "Killing #{org.name}..."

  begin
    org.delete! :recursive => true
  rescue CFoundry::APIError
    puts "FAILED"
  end
end

puts "the deed is done"
