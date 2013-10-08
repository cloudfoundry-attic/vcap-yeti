require "cfoundry"

module CFoundryHelpers
  def make_app
    @session.client.app.tap do |app|
      app.name = SecureRandom.uuid
    end
  end

  def make_domain(name)
    @session.client.domain.tap do |domain|
      domain.name = name
      domain.wildcard = true
      domain.owning_organization = @session.current_organization
    end
  end

  def make_route(domain, host = SecureRandom.uuid)
    @session.client.route.tap do |route|
      route.host = host
      route.domain = domain
      route.space = @session.current_space
    end
  end

  def map_route(app, host = SecureRandom.uuid, domain = @session.client.domains.first)
    route = make_route(domain, host)
    route.create!

    app.add_route(route)

    route
  end

  #blocks until the app is actually running
  def start_app_blocking(app, wait_time=15)
    app.start!(&staging_callback)

    Timeout::timeout(wait_time) do
      sleep(1) until app.running?
    end
  end

  def get_endpoint(app, path)
    raise "No routes mapped to app: #{app.name}" unless app.url
    Net::HTTP.get(URI.parse("http://#{app.url}#{path}"))
  end

  def staging_callback(blk = nil)
    proc do |url|
      next unless url

      if blk
        blk.call(url)
      elsif url
        stream_update_log(url) do |chunk|
          puts "       STAGE LOG => #{chunk}"
        end
      end
    end
  end

  def stream_update_log(log_url)
    offset = 0

    while true
      begin
        @session.client.stream_url(log_url + "&tail&tail_offset=#{offset}") do |out|
          offset += out.size
          yield out
        end
      rescue Timeout::Error
      end
    end
  rescue CFoundry::APIError
  end
end