require "harness"
require "spec_helper"
require "nokogiri"
include BVT::Spec
include BVT::Spec::AutoStagingHelper

describe BVT::Spec::AutoStaging::JavaSpring do

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def add_env(app, key, value)
    env = {"#{key}"=>"#{value}"}
    manifest = {}
    manifest['env'] = env
    app.update!(manifest)
  end

  def add_records(app, number, path='')
    records = {}
    1.upto number do |i|
      key = "key-#{i}"
      value = "FooBar-#{i}"
      records[key] = value
      response = app.get_response(:post, path, Curl::PostField.content("name", value))
      response.response_code.should == 302
    end
    records
  end

  def verify_records(app, records, number, path='', xpath='//li/p')
    response = app.get_response(:get, path)
    response.should_not == nil
    response.response_code.should == 200
    verify_contents(records, number, response.body_str, xpath)
  end

  def verify_contents(records, count, contents, path)
    doc = Nokogiri::XML(contents)
    list = doc.xpath(path)
    list.length.should == count
    records.values.each do |record_val|
      record_present(record_val, list)
    end
  end

  def record_present record, list
    list.each do |item|
      if item.content.include? record
        return true
      end
    end
    nil
  end

  it "Spring Web Application specifying a Cloud Service and Data Source",
    :mysql => true, :mongodb => true, :p1 => true do
    app = create_push_app("auto-reconfig-test-app")
    bind_service(MONGODB_MANIFEST, app)
    bind_service(MYSQL_MANIFEST, app)

    add_env(app,'TEST_PROFILE','auto-staging-off-using-cloud-service')

    response = app.get_response(:get, "/mysql")
    response.should_not == nil
    response.response_code.should == 200
    response.body_str.should == 'jdbc:mysql://localhost:3306/vcap-java-test-app'
  end

  it "Spring Web Application specifying a Service Scan and Data Source",
    :mysql => true do
    app = create_push_app("auto-reconfig-test-app")
    bind_service(MYSQL_MANIFEST, app)

    add_env(app,'TEST_PROFILE','auto-staging-off-using-service-scan')

    response = app.get_response(:get, "/mysql")
    response.should_not == nil
    response.response_code.should == 200
    response.body_str.should == 'jdbc:mysql://localhost:3306/vcap-java-test-app'
  end

  it "Spring Web Application using a local MongoDBFactory", :mongodb => true do
    app = create_push_app("auto-reconfig-test-app")
    bind_service(MONGODB_MANIFEST, app)

    add_env(app,'TEST_PROFILE','mongo-auto-staging')

    response = app.get_response(:get, "/mongo")
    response.should_not == nil
    response.response_code.should == 200
    response.body_str.should =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{4,5}/
  end

  it "Spring Web Application using a local RedisConnectionFactory",
    :redis => true, :p1 => true do
    app = create_push_app("auto-reconfig-test-app")
    bind_service(REDIS_MANIFEST, app)

    add_env(app,'TEST_PROFILE','redis-auto-staging')

    response = app.get_response(:get, "/redis/host")
    response.should_not == nil
    response.response_code.should == 200
    response.body_str.should =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{4,5}/
  end

  it "Spring Web Application using a local RabbitConnectionFactory",
    :rabbitmq => true, :p1 => true do
    app = create_push_app("auto-reconfig-test-app")
    bind_service(RABBITMQ_MANIFEST, app)

    add_env(app,'TEST_PROFILE','rabbit-auto-staging')

    response = app.get_response(:get, "/rabbit")
    response.should_not == nil
    response.response_code.should == 200
    response.body_str.should =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{4,5}/
  end

  it "Spring 3.1 Hibernate application using a local DataSource",
    :mysql => true do
    app = create_push_app("auto-reconfig-test-app")
    bind_service(MYSQL_MANIFEST, app)

    add_env(app,'TEST_PROFILE','hibernate-auto-staging')

    response = app.get_response(:get, "/hibernate")
    response.should_not == nil
    response.response_code.should == 200
    response.body_str.should == 'org.hibernate.dialect.MySQLDialect'
  end

  it "Start Spring Web Application with no service dependencies" do
    app = create_push_app("auto-reconfig-missing-deps-test-app")

    response = app.get_response(:get)
    response.should_not == nil
    response.response_code.should == 200
  end

  it "start Spring 3.1 Hibernate application with an annotation context using" +
     " a local DataSource", :mysql => true do
    app = create_push_app("auto-reconfig-annotation-app")
    bind_service(MYSQL_MANIFEST, app)

    response = app.get_response(:get, "/hibernate")
    response.should_not == nil
    response.response_code.should == 200
    response.body_str.should == 'org.hibernate.dialect.MySQLDialect'
  end

  it "Spring Web application using JPA using mysql", :mysql => true do
    app = create_push_app("jpa_app")
    service = bind_service(MYSQL_MANIFEST, app)

    records = add_records(app, 3)

    verify_records(app, records, 3)

    app.delete

    app2 = create_push_app("jpa_app")
    app2.bind(service)

    verify_records(app2, records, 3)
  end

  it "Spring Web application using Hibernate and mysql", :mysql => true do
    app = create_push_app("hibernate_app")
    service = bind_service(MYSQL_MANIFEST, app)

    records = add_records(app, 3)

    verify_records(app, records, 3)

    app.delete

    app2 = create_push_app("hibernate_app")
    app2.bind(service)

    verify_records(app2, records, 3)
  end

  it "Spring Roo application using mysql", :mysql => true do
    app = create_push_app("roo_app")
    service = bind_service(MYSQL_MANIFEST, app)

    records = add_records(app, 3, '/guests')

    # The Roo page returns an extra row for the footer in the table
    # hence the "+ 1"
    verify_records(app, records, 4, '/guests', '//table/tr')

    app.delete

    app2 = create_push_app("roo_app")
    app2.bind(service)

    # The Roo page returns an extra row for the footer in the table
    # hence the "+ 1"
    verify_records(app2, records, 4, '/guests', '//table/tr')
  end

  it "Spring Web application using Hibernate and postgresql",
    :postgresql => true, :p1 => true do
    app = create_push_app("hibernate_app")
    service = bind_service(POSTGRESQL_MANIFEST, app)

    records = add_records(app, 3)

    verify_records(app, records, 3)

    app.delete

    app2 = create_push_app("hibernate_app")
    app2.bind(service)

    verify_records(app2, records, 3)
  end

  it "Start Spring Web Application with no service dependencies" do
    app = create_push_app("javaee-namespace-app")

    response = app.get_response(:get)
    response.should_not == nil
    response.response_code.should == 200
  end

end

