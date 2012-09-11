module CFoundry
  class Client < BaseClient
    def self.new(*args)
      target, _ = args

      base = super(target)
      CFoundry::V1::Client.new(*args)

    end
  end
end
