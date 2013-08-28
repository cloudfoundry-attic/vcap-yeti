module WaitHelper
  def wait(retries_left = 20, &blk)
    blk.call
  rescue
    retries_left -= 1
    if retries_left > 0
      sleep(1)
      retry
    else
      raise
    end
  end
end

RSpec.configure do |config|
  config.include(WaitHelper)
end
