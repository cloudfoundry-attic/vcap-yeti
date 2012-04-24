module BVT
  module Spec

    module UsersManagement
      class AdminUser; end
    end

    module AutoStaging
      class Ruby18Rack; end

      class Ruby19Sinatra; end
      class Ruby19Rack; end
      class Ruby19Rails3; end

      class JavaSpring; end
    end

    module Canonical
      class JavaSpring; end
    end

    module Simple
      class JavaWeb; end
    end

    MYSQL_MANIFEST      = {"vendor"=>"mysql", "version"=>"5.1"}
    REDIS_MANIFEST      = {"vendor"=>"redis", "version"=>"2.2"}
    MONGODB_MANIFEST    = {"vendor"=>"mongodb", "version"=>"1.8"}
    RABBITMQ_MANIFEST   = {"vendor"=>"rabbitmq", "version"=>"2.4"}
    POSTGRESQL_MANIFEST = {"vendor"=>"postgresql", "version"=>"9.0"}

    SERVICE_URL_MAPPING = Hash["mysql" => "mysql",
                               "redis" => "redis",
                               "mongodb" => "mongo",
                               "rabbitmq" => "rabbitmq",
                               "postgresql" => "postgresql"]

    SERVICE_URL_MAPPING_UNSUPPORTED_VERSION = Hash["mysql" => "mysql",
                                                   "redis" => "redis",
                                                   "mongodb" => "mongo",
                                                   "rabbitmq" => "amqp",
                                                   "postgresql" => "postgres"]
  end
end

require "autostaging/autostaging_helper"
