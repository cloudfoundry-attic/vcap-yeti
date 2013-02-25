require 'console-vmc-plugin/console'

module BVT::Harness
  module ConsoleHelpers

    def init_console(client, app, port = 10000)
      console = CFConsole.new(client, app)
      port = console.pick_port!(port)
      console.open!
      console.wait_for_start
      logged_in = false
      3.times do
        begin
          console.login
          logged_in = true
          break
        rescue => e
          puts "Unable to login to console: #{e}. Retrying."
          sleep 1
        end
      end
      logged_in.should be_true, "rails console connection " +
        "cannot be established in 3 times"
      console
    end

  end
end

