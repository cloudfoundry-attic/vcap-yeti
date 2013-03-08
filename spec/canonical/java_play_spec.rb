require "harness"
require "spec_helper"
include BVT::Spec
include BVT::Spec::CanonicalHelper

describe "Canonical::JavaPlay" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    show_crashlogs
    @session.cleanup!
  end

  def bind_service_to_unstarted_app(service, app)
    manifest = {}
    app.services = [service]
    app.update!
  end

  def verify_file(file_list, file1)
    has_file = false
    file_list.each {|f|
      if f[1] == file1
        has_file = true
        break
      end
    }
    has_file
  end

  it "play application with mysql auto-reconfiguration", :mysql => true, :p1 => true do
    app = create_push_app("play_todolist_app_20", nil, nil, [MYSQL_MANIFEST])

    contents = app.get_response(:get, '/tasks')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("Auto-reconfiguring default")
    log.should include("database [default] connected at jdbc:mysql")
  end

  it "play application using cloud foundry runtime lib", :mysql => true do
    app = create_push_app("play_todolist_with_cfruntime_app_21", nil, nil, [MYSQL_MANIFEST])

    contents = app.get_response(:get, '/tasks')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("Found cloudfoundry-runtime lib.  " +
                         "Auto-reconfiguration disabled")
    log.should include("database [default] connected at jdbc:h2")
  end

  it "play 2.0 application using cloud properties for mysql configuration by " + "service name", :mysql => true do
    app = create_app("play_zentasks_cf_by_name_app_20")

    service = create_service(MYSQL_MANIFEST, "play_zentasks_cf_by_name_appmysql")
    app.push([service])

    contents = app.get_response(:get, '/login')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("Found cloud properties in configuration.  " +
                         "Auto-reconfiguration disabled")
    log.should include("database [default] connected at jdbc:mysql")

    files = app.files("/app/lib/")
    has_file = verify_file(files, "mysql-connector-java-5.1.12-bin.jar")

    has_file.should == false
  end

  it "play 2.1 application using cloud properties for mysql configuration " +
       "by service type", :mysql => true do
    app = create_app("play_zentasks_cf_by_type_app_21")

    service = create_service(MYSQL_MANIFEST)
    app.push([service])

    contents = app.get_response(:get, '/login')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("Found cloud properties in configuration.  " +
                         "Auto-reconfiguration disabled")
    log.should include("database [default] connected at jdbc:mysql")
  end

  it "play 2.0 application with auto-reconfiguration disabled", :mysql => true do
    app = create_push_app("play_computer_database_autoconfig_disabled_app_20", nil, nil, [MYSQL_MANIFEST])

    contents = app.get_response(:get, '/computers')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("User disabled auto-reconfiguration")
    log.should include("database [default] connected at jdbc:h2")
  end

  it "play 2.0 application using cloud properties for postgresql configuration " +
       "by service name", :postgresql => true do
    app = create_app("play_computer_database_cf_by_name_app_20")

    service = create_service(POSTGRESQL_MANIFEST,
                             "play_computer_database_cf_by_name_apppostgresql")
    app.push([service])

    contents = app.get_response(:get, '/computers')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("Found cloud properties in configuration.  " +
                         "Auto-reconfiguration disabled")
    log.should include("database [default] connected at jdbc:postgresql")

    files = app.files("/app/lib/")
    has_file = verify_file(files, "postgresql-9.0-801.jdbc4.jar")

    has_file.should == false
  end

  it "play 2.0 application using cloud properties for postgresql configuration " +
       "by service type", :postgresql => true do
    app = create_app("play_computer_database_cf_by_type_app_20")

    service = create_service(POSTGRESQL_MANIFEST)

    app.push([service])

    contents = app.get_response(:get, '/computers')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("Found cloud properties in configuration.  " +
                         "Auto-reconfiguration disabled")
    log.should include("database [default] connected at jdbc:postgresql")

    files = app.files("/app/lib/")
    has_file = verify_file(files, "postgresql-9.0-801.jdbc4.jar")

    has_file.should == false
  end

  it "play 2.0 application with mysql JPA auto-reconfiguration",
     :mysql => true do
    app = create_push_app("play_computer_database_jpa_mysql_app_20", nil, nil, [MYSQL_MANIFEST])

    contents = app.get_response(:get, '/computers')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("Auto-reconfiguring default")
    log.should include("database [default] connected at jdbc:mysql")
  end

  it "play 2.1 application with postgresql JPA auto-reconfiguration",
     :postgresql => true, :p1 => true do
    app = create_push_app("play_computer_database_jpa_app_21", nil, nil, [POSTGRESQL_MANIFEST])

    contents = app.get_response(:get, '/computers')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("Auto-reconfiguring default")
    log.should include("database [default] connected at jdbc:postgresql")
  end

  it "play 2.0 application with multiple databases", :mysql => true,
     :postgresql => true do
    app = create_push_app("play_computer_database_multi_dbs_app_20", nil, nil, [POSTGRESQL_MANIFEST, MYSQL_MANIFEST])

    contents = app.get_response(:get, '/computers')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("Found multiple databases in Play configuration.  " +
                         "Skipping auto-reconfiguration")
    log.should include("database [default] connected at jdbc:h2")
  end

  it "play 2.0 application with postgres auto-reconfiguration",
     :postgresql => true do
    app = create_push_app("play_computer_database_scala_app_20", nil, nil, [POSTGRESQL_MANIFEST])

    contents = app.get_response(:get, '/computers')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("Auto-reconfiguring default")
    log.should include("database [default] connected at jdbc:postgresql")
  end

  it "play 2.0 application with multiple database services, one named production",
    :slow => true,
    :postgresql => true do
    app = create_push_app("play_computer_database_scala_app_20", nil, nil, [POSTGRESQL_MANIFEST])
    bind_service(POSTGRESQL_MANIFEST, app, 'play-comp-db-app-production')

    contents = app.get_response(:get, '/computers')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("Auto-reconfiguring default")
    log.should include("database [default] connected at jdbc:postgresql")
  end

  it "play 2.0 application with multiple database services", :mysql => true, :postgresql => true do
    app = create_push_app("play_computer_database_scala_app_20", nil, nil, [POSTGRESQL_MANIFEST, MYSQL_MANIFEST])

    contents = app.get_response(:get, '/computers')
    contents.should_not == nil
    contents.to_str.should_not == nil
    contents.code.should == 200

    log = app.logs
    log.should_not == nil
    log.should include("Found 0 or multiple database services bound to app.  " +
                         "Skipping auto-reconfiguration")
    log.should include("database [default] connected at jdbc:h2")
  end
end
