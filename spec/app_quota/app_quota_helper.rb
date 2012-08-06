require "harness"
require "pp"

module BVT::Harness
  module AppQuotaHelper
    # time out in secs
    VCAP_APP_QUOTA_TIME_OUT = 60 * 1000
    VCAP_APP_QUOTA_LOOP_INTERVAL = 2

    # detect limit for ram and hd
    def detect_hardware_limit(app, type, n)
      path = "/eat"
      if type == :mem
        path += "/ram?n=#{n}"
      elsif type ==:disk
        path += "/harddisk?n=#{n}"
      else
        raise "hardware type :#{type.to_s} is not supported"
      end

      app_stats = app.stats

      # the below harness method is to be implemented
      crashes = app.crashes
      start = Time.new
      # send the request to start eat resources
      app.get_response(:get, path)

      while Time.new - start < VCAP_APP_QUOTA_TIME_OUT
        if new_crash?(app, crashes)
          break
        else
          app_stats = app.stats
          sleep VCAP_APP_QUOTA_LOOP_INTERVAL
        end
      end

      if Time.new - start >= VCAP_APP_QUOTA_TIME_OUT
        raise "Time out while running app quota tests"
      end

      app_stats[:"0"][:stats][:usage][type]
    end

    # to tell if there is a new crash happened
    # todo
    def new_crash?(app, crashes)
      now_crashes = app.crashes
      # compare now_crashes and crashes
      # faked comparison code, todo
      if now_crashes == crashes
        return false
      else
        return true
      end
    end
  end
end
