require "harness"
require "spec_helper"
require "harness/rake_helper"
require "verification/services"

include BVT::Spec
include BVT::Harness::RakeHelper
include BVT::Verification::Services

describe "Mysql RDS Service" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  let(:service_plan) {"10mb"}
  let(:service_info) {{:vendor=>"rds_mysql", :version=>"n/a", :plan => service_plan, :provider => "aws"}}
  let(:provision_name) { "yoursql"}

  it "allows users to provision, bind, and insert into a mysql instance to a certain data size" do
    service_instance = create_service(service_info, provision_name)

    service_list = @session.current_space.service_instances
    service_list.should have(1).item
    provisioned_service = service_list.first

    provisioned_service.name.should == provision_name
    provisioned_service.service_plan.name.should == service_plan
    provisioned_service.service_plan.service.label.should == "rds_mysql"
    provisioned_service.service_plan.service.provider.should == "aws"
    provisioned_service.service_plan.service.version.should == "n/a"

    app = create_app("app_sinatra_service")
    app.push([service_instance])

    app.services.should include(service_instance.instance)
    verify_keys(app, "mysql")

    app.get_response(:post, '/service/mysql/query', "create table big (bronies char(180))")
    app.get_response(:post, '/service/mysql/query', "insert into big values ('rainbow warrior')")
    16.times do
      app.get_response(:post, '/service/mysql/query', "insert into big select * from big")
    end
    query = <<-QUERY
      use information_schema;
      select concat(round(sum(DATA_LENGTH/1024/1024),2),'MB') as data from TABLES
    QUERY
    app.get_response(:post, '/service/mysql/query', query)

    response = nil
    25.times do
      insert_query = "insert into big values ('i am not allowed')"
      puts insert_query
      response = app.get_response(:post, '/service/mysql/query', insert_query)
      break if response.to_str =~ /error/i
      sleep 1
    end
    response.to_str.should =~ /Error.*INSERT command denied/
  end
end
