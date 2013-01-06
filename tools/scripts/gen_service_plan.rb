#!/usr/bin/ruby
require 'optparse'
require 'yaml'
require 'syck'
YAML::ENGINE.yamler = 'syck'

options = {}

optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: gen_service_plan.rb [options]"

  opts.on('-i', '--input [INPUT FILE]', String, 'input yml file contains service plans' ) do |inputfile|
   options[:input] = inputfile
  end

  opts.on('-o', '--output [OUTPUT FILE]', String, 'output the path of shell script' ) do |outputfile|
    options[:output] = outputfile
  end

  opts.on('-s', '--service [SERVICE NAME]', String, 'service name to be filtered' ) do |service|
    options[:service] = service
  end

  opts.on('-p', '--plan [SERVICE PLAN]', String, 'service plan to be filtered' ) do |service_plan|
    options[:plan] = service_plan
  end
  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on('-h', '--help', 'Display this help message' ) do
    puts opts
    exit
  end
end

optparse.parse!

if options[:input].nil?
  puts "require inputfile"
  exit(-1)
elsif not File.exist?(options[:input])
  puts "#{options[:input]} doesn't exist"
  exit(-1)
end
refs = open(options[:input]){|f| YAML.load(f)}

fd = open(options[:output], File::RDWR|File::TRUNC|File::CREAT, 0755)
fd.write "#!/bin/bash\n"

empty = true
first_line = true
SERVICE_LIST=['mysql','mongodb','redis','rabbit','postgresql','vblob']
refs['jobs'].each do |job|
  SERVICE_LIST.each do |service|
    next if options[:service] and service != options[:service]
    if job['name'] =~ /^#{service}_node.*$/ then
      if service != 'vblob' then
        service_default_version = job['properties']["#{service}_node"]['default_version']
        service_plan =  job['properties']['plan']
        next if options[:plan] and service_plan != options[:plan]
        if options[:service] or first_line
          if options[:service]
            fd.write "# Run #{service} with plan #{service_plan} and version #{service_default_version}\n"
          else
            fd.write "# Run plan #{service_plan}\n"
          end
          fd.write "export VCAP_BVT_SERVICE_PLAN=#{service_plan}\n"
          first_line = false
        end
        if service == 'rabbit'
          fd.write "export VCAP_BVT_RABBITMQ_MANIFEST='{:vendor=>\"rabbitmq\", :version => \"#{service_default_version}\"}'\n"
        else
          fd.write "export VCAP_BVT_#{service.upcase}_MANIFEST='{:vendor=>\"#{service}\", :version => \"#{service_default_version}\"}'\n"
        end
        fd.write "bundle exec rake services\n" if options[:service]
        empty = false
      else
        next if options[:plan] and service_plan != options[:plan]
        if options[:service] or first_line
          fd.write "export VCAP_BVT_SERVICE_PLAN=#{service_plan}\n"
          first_line = false
        end
        fd.write "bundle exec rake services\n" if options[:service]
        empty = false
      end
    end
  end
end
if empty
  puts "can't find any matched service plan"
  fd.close
  exit(-1)
end

fd.write "bundle exec rake services\n" unless options[:service]
fd.close

exit(0)
