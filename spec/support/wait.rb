module WaitHelper
  def wait(retries_left = 40, &blk)
    blk.call
  rescue
    retries_left -= 1
    if retries_left > 0
      sleep(0.5)
      retry
    else
      raise
    end
  end
end

RSpec.configure do |config|
  config.include(WaitHelper)
end
