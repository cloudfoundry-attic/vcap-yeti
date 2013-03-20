#!/usr/bin/env ruby
require "rubygems"
require "cfoundry"

client = CFoundry::Client.new(ENV["VCAP_BVT_TARGET"])
client.login(ENV["VCAP_BVT_ADMIN_USER"], ENV["VCAP_BVT_ADMIN_USER_PASSWD"])

puts "Going hunting..."

all_orgs = client.organizations
useless_orgs = all_orgs.select do |org|
  org.name =~ /(^org(anization)?-|yeti_test_org)/
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

routes = client.routes

useless_orgs.each do |org|
  puts "Killing #{org.name}..."

  begin
    org.delete!
  rescue CFoundry::InvalidRequest
    begin
      org.domains.each do |domain|
        next unless domain.owning_organization == org

        puts "  Clearing domain #{domain.name} first..."
        domain.delete!
        puts "  OK"
      end

      org.spaces.each do |space|
        puts "  Clearing space #{space.name} first..."

        begin
          space.delete!
        rescue CFoundry::InvalidRequest
          puts "    Clearing the space's contents first..."

          routes.select { |r| r.space == space }.each(&:delete!)

          space.apps.each do |app|
            puts "      Deleting app #{app.name}..."
            app.delete!
            puts "      OK"
          end

          space.service_instances.each do |svc|
            puts "      Deleting service instance #{svc.name}..."
            svc.delete!
            puts "      OK"
          end

          space.delete!
          puts "    OK"
        end

        puts "  OK"
      end

      org.delete!

      puts "OK"
    rescue CFoundry::InvalidRequest
      puts "FAILED"
      next
    end
  end
end

puts "the deed is done"
