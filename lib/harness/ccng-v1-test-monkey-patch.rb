module CFoundry
  class Client < BaseClient
    def self.new(*args)
      target, _ = args

      base = super(target)
      CFoundry::V1::Client.new(*args)

    end
  end
end

module CFoundry::V1
  # Class for representing a user's application on a given target (via
  # Client).
  #
  # Does not guarantee that the app exists; used for both app creation and
  # retrieval, as the attributes are all lazily retrieved. Setting attributes
  # does not perform any requests; use #update! to commit your changes.
  class App
    # Check if the application exists on the target.
    def exists?
      @client.base.app(@name)
      true
    rescue CFoundry::NotFound, CFoundry::Denied
      false
    end
  end
end
