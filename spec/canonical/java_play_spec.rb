require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Canonical::JavaPlay do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  LOG_STDOUT  = "logs/stdout.log"

  it "play application with mysql auto-reconfiguration", :play => true do

    pending "asset binary not yet available"
    app = create_push_app("play_todolist_app")

    bind_service( MYSQL_MANIFEST, app )

    contents = app.get_response( :get, '/tasks' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include("Auto-reconfiguring default")
    log.should include("database [default] connected at jdbc:mysql")

  end

  it "play application using cloud foundry runtime lib", :play => true do

    pending "asset binary not yet available"
    app = create_push_app("play_todolist_with_cfruntime_app")

    bind_service( MYSQL_MANIFEST, app )

    contents = app.get_response( :get, '/tasks' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include("Found cloudfoundry-runtime lib.  " +
      "Auto-reconfiguration disabled")
    log.should include("database [default] connected at jdbc:h2")

  end

  it "play application using cloud properties for mysql configuration by " +
    "service name", :play => true do

    pending "asset binary not yet available"

    app = create_push_app("play_zentasks_cf_by_name_app")

    bind_service( MYSQL_MANIFEST, app )

    contents = app.get_response( :get, '/login' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include("Found cloud properties in configuration.  " +
      "Auto-reconfiguration disabled")
    log.should include("database [default] connected at jdbc:mysql")

    files = app.files
    files.should_not                == nil

    # TODO: should not find app/lib/mysql-connector-java-5.1.12-bin.jar
    put files

  end

  it "play application using cloud properties for mysql configuration " +
    "by service type", :play => true do

    pending "asset binary not yet available"

    app = create_push_app("play_zentasks_cf_by_type_app")

    bind_service( MYSQL_MANIFEST, app )

    contents = app.get_response( :get, '/login' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include("Found cloud properties in configuration.  " +
      "Auto-reconfiguration disabled")
    log.should include("database [default] connected at jdbc:mysql")

    files = app.files
    files.should_not                == nil
    # should not find app/lib/postgresql-9.0-801.jdbc4.jar

  end

  it "play application with auto-reconfiguration disabled", :play => true do

    pending "asset binary not yet available"

    app = create_push_app("play_computer_database_autoconfig_disabled_app")

    bind_service( MYSQL_MANIFEST, app )

    contents = app.get_response( :get, '/computers' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include("User disabled auto-reconfiguration")
    log.should include("database [default] connected at jdbc:h2")

  end

  it "play application using cloud properties for postgresql configuration " +
    "by service name", :play => true do

    pending "asset binary not yet available"

    app = create_push_app("play_computer_database_cf_by_name_app")

    bind_service( MYSQL_MANIFEST, app )

    contents = app.get_response( :get, '/computers' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include("Found cloud properties in configuration.  " +
      "Auto-reconfiguration disabled" )
    log.should include("database [default] connected at jdbc:postgresql")

    files = app.files
    files.should_not                == nil
    # should not find app/lib/postgresql-9.0-801.jdbc4.jar

  end

  it "play application using cloud properties for postgresql configuration " +
    "by service type", :play => true do

    pending "asset binary not yet available"

    app = create_push_app("play_computer_database_cf_by_type_app")

    bind_service( POSTGRESQL_MANIFEST, app )

    contents = app.get_response( :get, '/computers' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include("Found cloud properties in configuration.  " +
      "Auto-reconfiguration disabled" )
    log.should include("database [default] connected at jdbc:postgresql")

    files = app.files
    files.should_not                == nil
    # should not find app/lib/postgresql-9.0-801.jdbc4.jar

  end

  it "play application with mysql JPA auto-reconfiguration", :play => true do

    pending "asset binary not yet available"

    app = create_push_app("play_computer_database_jpa_mysql_app")

    bind_service( POSTGRESQL_MANIFEST, app )

    contents = app.get_response( :get, '/computers' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include("Auto-reconfiguring default")
    log.should include("database [default] connected at jdbc:mysql")


  end

  it "play application with postgresql JPA auto-reconfiguration",
    :play => true do

    pending "asset binary not yet available"

    app = create_push_app("play_computer_database_jpa_app")

    bind_service( POSTGRESQL_MANIFEST, app )

    contents = app.get_response( :get, '/computers' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include("Auto-reconfiguring default")
    log.should include("database [default] connected at jdbc:postgresql")


  end

  it "play application with multiple databases", :play => true do

    pending "asset binary not yet available"

    app = create_push_app("play_computer_database_multi_dbs_app")

    bind_service( POSTGRESQL_MANIFEST, app )

    bind_service( MYSQL_MANIFEST, app )

    contents = app.get_response( :get, '/computers' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include("Found multiple databases in Play configuration.  " +
      "Skipping auto-reconfiguration")
    log.should include("database [default] connected at jdbc:h2")


  end

end
