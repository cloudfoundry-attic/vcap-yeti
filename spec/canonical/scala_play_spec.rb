require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Canonical::ScalaPlay do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
    @app = create_push_app("play_computer_database_scala_app")
  end

  after(:all) do
    @session.cleanup!
  end

  LOG_STDOUT  = "logs/stdout.log"

  it "play application with postgres auto-reconfiguration",
    :play => true, :scala => true do

    pending "asset binary not yet available"

    bind_service( POSTGRESQL_MANIFEST, @app )

    contents = @app.get_response( :get, '/computers' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = @app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include("Auto-reconfiguring default")
    log.should include("database [default] connected at jdbc:postgresql")

  end

  it "play application using scala with multiple database services, " +
    "one named production", :play => true, :scala => true do

    pending "asset binary not yet available"

    bind_service( POSTGRESQL_MANIFEST, @app )

    contents = @app.get_response( :get, '/computers' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = @app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include("Auto-reconfiguring default")
    log.should include("database [default] connected at jdbc:postgresql")

  end

  it "play application using scala with multiple database services",
    :play => true, :scala => true do

    pending "asset binary not yet available"

# provision a postgresql servfice named play-comp-db-app-production
    bind_service( POSTGRESQL_MANIFEST, @app )

    bind_service( POSTGRESQL_MANIFEST, @app )

    contents = @app.get_response( :get, '/computers' )
    contents.should_not             == nil
    contents.body_str.should_not    == nil
    contents.response_code.should   == 200
    contents.close

    log = @app.file(LOG_STDOUT)
    log.should_not == nil
    log.should include "Found 0 or multiple database services bound to app.  " +
      "Skipping auto-reconfiguration"
    log.should include "database [default] connected at jdbc:h2"

  end

end
