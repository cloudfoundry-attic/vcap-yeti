module BVT::Harness
  module LoggerHelper
    attr_reader :logfile
    module_function

    def set_logger(target)
      # setup logger
      filename    = target ? "bvt.#{target_without_http(target)}.log" : "bvt.log"
      logfile     = File.join(VCAP_BVT_HOME, filename)
      loglevel    = :debug
      config = {
          :level => loglevel,
          :file => logfile
      }

      Dir.mkdir(VCAP_BVT_HOME) unless Dir.exist?(VCAP_BVT_HOME)
      VCAP::Logging.reset
      VCAP::Logging.setup_from_config(config)
      VCAP::Logging.add_sink(:warn, nil, VCAP::Logging::Sink::StdioSink.new(STDOUT, VCAP::Logging::FORMATTER))
    end

    def target_without_http(target)
      target.split('//')[-1]
    end

  end
end
