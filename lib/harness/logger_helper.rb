
module BVT::Harness
  module LoggerHelper
    module_function

    def set_logger(target)
      # setup logger
      filename    = target ? "bvt.#{format_target(target)}.log" : "bvt.log"
      logfile     = File.join(VCAP_BVT_HOME, filename)
      loglevel    = :debug
      config = {:level => loglevel, :file => logfile}
      Dir.mkdir(VCAP_BVT_HOME) unless Dir.exist?(VCAP_BVT_HOME)
      VCAP::Logging.setup_from_config(config)
    end

    def format_target(str)
      if str.start_with? 'http://api.'
        str.gsub('http://api.', '')
      elsif str.start_with? 'api.'
        str.gsub('api.', '')
      else
        str
      end
    end
  end
end