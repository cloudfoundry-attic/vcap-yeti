# encoding: UTF-8

require "harness"
require "spec_helper"

include BVT::Spec

describe "Tools::Loggregator", :loggregator => true do
  def tmp_dir
    File.expand_path(File.join(__FILE__, "../../../tmp"))
  end

  def cli_path
    tmp_dir + "/go-cf"
  end

  def windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def linux?
    !windows? && !mac?
  end

  def system_architecture
    return :linux if linux?
    return :mac if mac?
  end

  def download_cli_for_arch
    binary_urls = {
      :mac    => "https://go-cli.s3.amazonaws.com/go-cf-darwin-amd64.tgz",
      :win386 => "https://go-cli.s3.amazonaws.com/go-cf-windows-386.tgz",
      :win64  => "https://go-cli.s3.amazonaws.com/go-cf-windows-amd64.tgz",
      :linux  => "https://go-cli.s3.amazonaws.com/go-cf-linux-amd64.tgz"
    }

    Dir.mkdir(tmp_dir) unless File.exists?(tmp_dir)
    new_file_path = File.join(tmp_dir, "go-cli")

    `wget #{binary_urls[system_architecture]} -O #{new_file_path}.tgz && tar xzf #{new_file_path}.tgz -C #{tmp_dir}`
  end

  before(:all) do
    @session = BVT::Harness::CFSession.new
    download_cli_for_arch
  end

  after(:all) do
    @session.cleanup!
    BlueShell::Runner.run "#{cli_path} logout"
  end

  with_app "loggregator"

  it "can tail app logs" do
    begin
      Timeout.timeout(10) do
        loop { break if app.application_is_really_running? }
      end
    rescue Timeout::Error
      raise "Loggregator test app didn't startup correctly"
    end

    BlueShell::Runner.run "#{cli_path} api #{@session.api_endpoint}"
    BlueShell::Runner.run "#{cli_path} login #{@session.email} #{@session.passwd}"
    BlueShell::Runner.run "#{cli_path} target -o #{@session.current_organization.name} -s #{@session.current_space.name}"
    BlueShell::Runner.run "#{cli_path} logs #{app.name}" do |runner|
      runner.should have_output 'Connected, tailing...'

      number_of_tries = 0
      all_log_messages_received = false
      while !all_log_messages_received && number_of_tries < 100 do
        app.get_response(:get)

        all_log_messages_received =
            runner.output.match(/\[App/) &&
            runner.output.match(/\[Router/) &&
            runner.output.match(/#{app.get_url}/) &&
            runner.output.match(/Hello on STDOUT/) &&
            runner.output.match(/Hello on STDERR/)

        sleep 0.3
        number_of_tries += 1
      end

      if !all_log_messages_received
        fail "Expected to see output from router and app, but did not get it. Output was: #{runner.output}"
      else
        puts "It took #{number_of_tries} to get the required log output for the running app"
      end

      app.restart

      number_of_tries = 0
      all_log_messages_received = false
      while !all_log_messages_received && number_of_tries < 100 do
        all_log_messages_received =
            runner.output.match(/\[API/) &&
                runner.output.match(/\[Executor/) &&
                runner.output.match(/#{app.get_url}/) &&
                runner.output.match(/Updated app with guid #{app.guid}/) &&
                runner.output.match(/Registering instance/)

        sleep 0.3
        number_of_tries += 1
      end


      if !all_log_messages_received
        fail "Expected to see output from app restarting from Executor and API, but did not get it. Output was: #{runner.output}"
      else
        puts "It took #{number_of_tries} to get the required log output when restarting the app"
      end

      runner.kill
    end
  end
end
