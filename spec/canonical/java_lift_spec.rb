require "harness"
require "spec_helper"
require "nokogiri"

describe BVT::Spec::Canonical::JavaLift do
  include BVT::Spec::CanonicalHelper, BVT::Spec

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:all) do
    @session.cleanup!
  end

  def verify_contents(count, contents, path, records)
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

  def post_xml_content(url, content)
    response = RestClient.post url, content, :content_type => 'text/xml', :accept => 'text/xml'
    response.code
  end

  it "deploy simple Scala / Lift Application", :lift => true do
    pending("lift script is not ready")
    app = create_push_app("simple-lift-app")

    response = app.get_response(:get)
    response.should_not == nil
    response.response_code.should == 200
    response.body_str.should =~ /scala_lift/
  end

  it "start Scala / Lift application and add some records", :lift => true do
    pending("lift script is not ready")
    app = create_push_app("lift-db-app")

    service = bind_service(MYSQL_MANIFEST, app)

    records = {}
    uri = app.manifest['uris'][0] + "/api/guests"
    1.upto 3 do |i|
      key = "key-#{i}"
      content = "<guest><name>#{key}</name></guest>"
      records[key] = content
      response = post_xml_content(uri, content)
      response.should == 200
    end

    response = RestClient.get uri, :accept => 'text/xml'
    response.should_not == nil
    response.code.should == 200
    verify_contents(3, response.body, "//guest", records)

    app.delete

    app2 = create_push_app("lift-db-app")
    app2.bind(service.name)

    uri = app2.manifest['uris'][0] + "/api/guests"
    response = RestClient.get uri, :accept => 'text/xml'
    response.should_not == nil
    response.code.should == 200
    verify_contents(3, response.body, "//guest", records)
  end
end
