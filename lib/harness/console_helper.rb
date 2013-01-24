require 'console-vmc-plugin/console'

module BVT::Harness
  module ConsoleHelpers

    def init_console(client, app, port = 10000)
      3.times do
        begin
          @console = CFConsole.new(client, app)
          port = @console.pick_port!(port)
          @console.open!
          @console.wait_for_start
          prompt = @console.login
          @console
          break
        rescue => e
          sleep 1
        end
      end
      @console.should_not be_nil, "rails console connection " +
        "cannot be established in 3 times"
      @console
    end

  end
end

