require "harness"
require "spec_helper"
require "nokogiri"
include BVT::Spec
include BVT::Spec::AutoStagingHelper

describe "AutoStaging::JavaSpring" do

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def add_env(app, key, value)
    app.env[key] = value
    app.update!
  end

  def add_records(app, number, path='')
    records = {}
    1.upto number do |i|
      key = "key-#{i}"
      value = "FooBar-#{i}"
      records[key] = value
      response = app.get_response(:post, path, "name" => value)
      response.code.should == 302
    end
    records
  end

  def verify_records(app, records, number, path='', xpath='//li/p')
    response = app.get_response(:get, path)
    response.should_not == nil
    response.code.should == 200
    verify_contents(records, number, response.to_str, xpath)
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
    :slow => true,
    :mysql => true, :mongodb => true, :p1 => true do
    app = create_push_app("auto-reconfig-test-app", nil, nil, [MONGODB_MANIFEST, MYSQL_MANIFEST])

    add_env(app,'TEST_PROFILE','auto-staging-off-using-cloud-service')

    response = app.get_response(:get, "/mysql")
    response.should_not == nil
    response.code.should == 200
    response.to_str.should == 'jdbc:mysql://localhost:3306/vcap-java-test-app'
  end

  it "Spring Web Application specifying a Service Scan and Data Source",
    :slow => true,
    :mysql => true do
    app = create_push_app("auto-reconfig-test-app", nil, nil, [MYSQL_MANIFEST])

    add_env(app,'TEST_PROFILE','auto-staging-off-using-service-scan')

    response = app.get_response(:get, "/mysql")
    response.should_not == nil
    response.code.should == 200
    response.to_str.should == 'jdbc:mysql://localhost:3306/vcap-java-test-app'
  end

  it "Spring Web Application using a local MongoDBFactory", :slow => true, :mongodb => true do
    app = create_push_app("auto-reconfig-test-app", nil, nil, [MONGODB_MANIFEST])

    add_env(app,'TEST_PROFILE','mongo-auto-staging')

    response = app.get_response(:get, "/mongo")
    response.should_not == nil
    response.code.should == 200
    response.to_str.should =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{4,5}/
  end

  it "Spring Web Application using a local RedisConnectionFactory",
    :slow => true,
    :redis => true, :p1 => true do
    app = create_push_app("auto-reconfig-test-app", nil, nil, [REDIS_MANIFEST])

    add_env(app,'TEST_PROFILE','redis-auto-staging')

    response = app.get_response(:get, "/redis/host")
    response.should_not == nil
    response.code.should == 200
    response.to_str.should =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{4,5}/
  end

  it "Spring Web Application using a local RabbitConnectionFactory",
    :slow => true,
    :rabbitmq => true, :p1 => true do
    app = create_push_app("auto-reconfig-test-app", nil, nil, [RABBITMQ_MANIFEST])

    add_env(app,'TEST_PROFILE','rabbit-auto-staging')

    response = app.get_response(:get, "/rabbit")
    response.should_not == nil
    response.code.should == 200
    response.to_str.should =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{4,5}/
  end

  it "Spring 3.1 Hibernate application using a local DataSource",
    :slow => true,
    :mysql => true do
    app = create_push_app("auto-reconfig-test-app", nil, nil, [MYSQL_MANIFEST])

    add_env(app,'TEST_PROFILE','hibernate-auto-staging')

    response = app.get_response(:get, "/hibernate")
    response.should_not == nil
    response.code.should == 200
    response.to_str.should == 'org.hibernate.dialect.MySQLDialect'
  end

  it "Start Spring Web Application with no service dependencies" do
    app = create_push_app("auto-reconfig-missing-deps-test-app")

    response = app.get_response(:get)
    response.should_not == nil
    response.code.should == 200
  end

  it "start Spring 3.1 Hibernate application with an annotation context using" +
     " a local DataSource", :mysql => true do
    app = create_push_app("auto-reconfig-annotation-app", nil, nil, [MYSQL_MANIFEST])

    response = app.get_response(:get, "/hibernate")
    response.should_not == nil
    response.code.should == 200
    response.to_str.should == 'org.hibernate.dialect.MySQLDialect'
  end

  it "Spring Web application using JPA using mysql",
    :slow => true,
    :mysql => true do
    app = create_push_app("jpa_app", nil, nil, [MYSQL_MANIFEST])

    records = add_records(app, 3)

    verify_records(app, records, 3)
  end

  it "Spring Web application using Hibernate and mysql", :mysql => true do
    app = create_push_app("hibernate_app", nil, nil, [MYSQL_MANIFEST])

    records = add_records(app, 3)

    verify_records(app, records, 3)
  end

  it "Spring Roo application using mysql", :mysql => true, :slow => true do
    app = create_push_app("roo_app", nil, nil, [MYSQL_MANIFEST])

    records = add_records(app, 3, '/guests')

    # The Roo page returns an extra row for the footer in the table
    # hence the "+ 1"
    verify_records(app, records, 4, '/guests', '//table/tr')
  end

  it "Spring Web application using Hibernate and postgresql",
    :postgresql => true, :p1 => true do
    app = create_push_app("hibernate_app", nil, nil, [POSTGRESQL_MANIFEST])

    records = add_records(app, 3)

    verify_records(app, records, 3)
  end

  it "Start Spring Web Application with no service dependencies" do
    app = create_push_app("javaee-namespace-app")

    response = app.get_response(:get)
    response.should_not == nil
    response.code.should == 200
  end

end

