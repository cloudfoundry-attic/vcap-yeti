
module BVT::Spec
  module RailsConsoleHelper
    def run_console(appname)
      #Console may not be available immediately after app start
      #if system is under heavy load.  Try a few times.
      3.times do
        begin
          local_console_port = @console_cmd.console appname, false
          @session.log.debug("console port: #{local_console_port}")
          creds = @console_cmd.console_credentials appname
          @session.log.debug("creds: #{creds}")
          prompt = @console_cmd.console_login(creds, local_console_port)
          @console_response = [prompt]
          break
        rescue VMC::Cli::CliExit, Errno::ECONNREFUSED => e
          @session.log.debug("Fail to connect rails console, retrying. #{e.to_s}")
          sleep 1
        end
      end
      @console_response.should_not be_nil, "rails console connection " +
          "cannot be established in 3 times"
    end

    def send_cmd_and_verify(cmd, expect)
      @console_response = @console_cmd.send_console_command(cmd)
      matched = false
      @console_response.each do |response|
        matched = true if response=~ /#{Regexp.escape(expect)}/
      end
      matched.should == true

    end
  end
end
