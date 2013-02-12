module BVT::Spec
  ## default service manifest
  MYSQL_MANIFEST            = ENV['VCAP_BVT_MYSQL_MANIFEST'] ? eval(ENV['VCAP_BVT_MYSQL_MANIFEST']) :
                              {:vendor=>"mysql", :version=>"5.5"}
  REDIS_MANIFEST            = ENV['VCAP_BVT_REDIS_MANIFEST'] ? eval(ENV['VCAP_BVT_REDIS_MANIFEST']) :
                              {:vendor => "redis", :version=>"2.6"}
  MONGODB_MANIFEST          = ENV['VCAP_BVT_MONGODB_MANIFEST'] ? eval(ENV['VCAP_BVT_MONGODB_MANIFEST']) :
                              {:vendor => "mongodb", :version=>"2.2"}
  RABBITMQ_MANIFEST         = ENV['VCAP_BVT_RABBITMQ_MANIFEST'] ? eval(ENV['VCAP_BVT_RABBITMQ_MANIFEST']) :
                              {:vendor => "rabbitmq", :version=>"2.8"}
  POSTGRESQL_MANIFEST       = ENV['VCAP_BVT_POSTGRESQL_MANIFEST'] ? eval(ENV['VCAP_BVT_POSTGRESQL_MANIFEST']) :
                              {:vendor => "postgresql", :version=>"9.1"}
  NEO4J_MANIFEST            = ENV['VCAP_BVT_NEO4J_MANIFEST'] ? eval(ENV['VCAP_BVT_NEO4J_MANIFEST']) :
                              {:vendor => "neo4j", :version=>"1.4"}
  BLOB_MANIFEST             = ENV['VCAP_BVT_BLOB_MANIFEST'] ? eval(ENV['VCAP_BVT_BLOB_MANIFEST']) :
                              {:vendor=>"blob", :version=>"0.51"}
  MEMCACHED_MANIFEST        = ENV['VCAP_BVT_MEMCACHED_MANIFEST'] ? eval(ENV['VCAP_BVT_MEMCACHED_MANIFEST']) :
                              {:vendor => "memcached",:version=>"1.4"}
  COUCHDB_MANIFEST          = ENV['VCAP_BVT_COUCHDB_MANIFEST'] ? eval(ENV['VCAP_BVT_COUCHDB_MANIFEST']) :
                              {:vendor => "couchdb",:version=>"1.2"}
  ELASTICSSEARCH_MANIFEST   = ENV['VCAP_BVT_ELASTICSSEARCH_MANIFEST'] ? eval(ENV['VCAP_BVT_ELASTICSSEARCH_MANIFEST']) :
                              {:vendor  =>  "elasticsearch", :version=>"0.19"}
  MPGW_TESTSERVICE_MANIFEST = ENV['VCAP_BVT_MPGW_TESTSERVICE_MANIFEST'] ? eval(ENV['VCAP_BVT_MPGW_TESTSERVICE_MANIFEST']) :
                              {:vendor => "testservice", :version=>"1.0", :provider => "TestProvider"}
  OAUTH2_MANIFEST      = ENV['VCAP_BVT_OAUTH2_MANIFEST'] ? eval(ENV['VCAP_BVT_OAUTH2_MANIFEST']) :
                              {:vendor=>"oauth2", :version=>"1.0"}
end
