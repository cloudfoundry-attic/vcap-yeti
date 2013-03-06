require 'console-vmc-plugin/console'

module BVT::Harness
  module ConsoleHelpers

    def init_console(client, app, port = 10000)
      console = CFConsole.new(client, app)      
      console.pick_port!(port)

      console_open(console)
      console_login(console)
      console
    end

    def console_open(console)
      console_retry(:console_open) do
        console.open!
        console.wait_for_start
      end
    end

    def console_login(console)
      console_retry(:console_login, 3, :sleep => 1) do
        console.login
      end
    end

    def console_retry(operation_name, tries=3, opts={}, &blk)
      tries -= 1
      blk.call
    rescue => e
      if tries >= 0
        puts "Retrying #{operation_name}"
        if opts[:sleep]
          puts "Sleeping #{opts[:sleep]}"
          sleep(opts[:sleep])
        end
        retry
      else
        puts "Failed to complete #{operation_name}"
        raise
      end
    end

  end
end

