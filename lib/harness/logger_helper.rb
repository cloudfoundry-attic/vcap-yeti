
module BVT::Harness
  module LoggerHelper
    attr_reader :logfile

    def set_logger(target)
      # setup logger
      if target
        domain_name = target.split('.', 2).last
        filename    = "bvt.#{domain_name}.log"
      else
        filename    = "bvt.log"
      end
      @logfile     = File.join(VCAP_BVT_HOME, filename)
      loglevel    = :debug
      config = {:level => loglevel, :file => logfile}
      Dir.mkdir(VCAP_BVT_HOME) unless Dir.exist?(VCAP_BVT_HOME)
      VCAP::Logging.setup_from_config(config)
    end

    extend self
  end
end
