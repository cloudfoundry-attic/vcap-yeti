require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Update::Ruby19Sinatra do
  include BVT::Spec

  VAR_INC_INSTANCE    = 2
  VAR_REDUCE_INSTANCE = 3
  VAR_USE_MEMORY      = 64

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  before(:each) do
    @app = create_push_app("simple_app2")
  end

  after(:each) do
    @session.cleanup!
  end

  it "increase/decrease instance count", :p1 => true do
    added_instance_count =  @app.instances.length + VAR_INC_INSTANCE
    @app.scale(added_instance_count, VAR_USE_MEMORY)
    @app.instances.length.should == added_instance_count

    reduced_instance_count = @app.instances.length - VAR_REDUCE_INSTANCE
    pending("there is one bug about app.update! method.")
    @app.scale(reduced_instance_count, VAR_USE_MEMORY)
    @app.instances.length.should == reduced_instance_count
  end

  it "map and unmap a url for the application to respond to", :p1 => true do
    second_domain_name = "new-app-url"
    new_url = @app.get_url(second_domain_name)
    @app.map(new_url)
    response = @app.get_response(:get, "/", nil, second_domain_name)
    response.body_str.should =~ /Hello from VCAP!/
    @app.get_response(:get).body_str.should =~ /Hello from VCAP!/

    url = @app.get_url
    @app.unmap(url)
    response = @app.get_response(:get, "/", nil, second_domain_name)
    response.body_str.should =~ /Hello from VCAP!/
    @app.get_response(:get).body_str.should =~ /404 Not Found/
    @app.urls.length.should be(1), "There are more than one url" +
        " mapped to application: #{@app.name}"
  end

  it "redeploy application", :p1 => true do
    @app.push(nil, "modified_simple_app2")
    @app.get_response(:get).body_str.should =~ /Hello from modified VCAP/
  end

end
