require "harness"
require "spec_helper"
include BVT::Spec

describe "Simple::Update" do

  VAR_INC_INSTANCE    = 4
  VAR_REDUCE_INSTANCE = 3
  VAR_USE_MEMORY      = 64

  before(:each) do
    @session = BVT::Harness::CFSession.new
  end

  before(:each) do
    @app = create_push_app("simple_app2")
  end

  after(:each) do
    @session.cleanup!
  end

  it "increase/decrease instance count" do
    added_instance_count =  @app.instances.length + VAR_INC_INSTANCE
    @app.scale(added_instance_count, VAR_USE_MEMORY)
    @app.instances.length.should == added_instance_count

    reduced_instance_count = @app.instances.length - VAR_REDUCE_INSTANCE
    @app.scale(reduced_instance_count, VAR_USE_MEMORY)
    @app.instances.length.should == reduced_instance_count
  end

  it "map and unmap a url for the application to respond to" do
    response = @app.get_response(:get, "/")
    response.to_str.should =~ /Hello from VCAP!/

    sleep 0.1
    @app.urls.length.should == 1
    second_domain_name = "new-app-url"
    new_url = @app.get_url(second_domain_name)
    @app.map(new_url)
    response = @app.get_response(:get, "/", nil, second_domain_name)
    response.to_str.should =~ /Hello from VCAP!/
    @app.get_response(:get).to_str.should =~ /Hello from VCAP!/

    url = @app.get_url
    @app.unmap(url)
    response = @app.get_response(:get, "/", nil, second_domain_name)
    response.to_str.should =~ /Hello from VCAP!/
    @app.get_response(:get).to_str.should =~ /404 Not Found/
    @app.urls.length.should be(1), "There are more than one url" +
        " mapped to application: #{@app.name}"
  end

  it "redeploy application" do
    @app.push(nil, "modified_simple_app2")
    @app.get_response(:get).to_str.should =~ /Hello from modified VCAP/
  end

end
