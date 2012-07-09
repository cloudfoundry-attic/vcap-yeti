
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
    end
  end
end
