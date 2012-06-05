require "harness"
require "spec_helper"

describe BVT::Spec::Simple::Update::Ruby19Sinatra do
  include BVT::Spec

  VAR_INC_INSTANCE    = 2
  VAR_REDUCE_INSTANCE = 1
  VAR_USE_MEMORY      = 64

  before(:each) do
    @session = BVT::Harness::CFSession.new
    @app = create_app("simple_app2")
    @app.push
    @app.healthy?.should be_true, "Application #{@app.name} is not running"
  end

  after(:each) do
    @session.cleanup!
  end

  it "increase instance count" do
    added_instance_count =  @app.instance.length + VAR_INC_INSTANCE
    @app.scale(added_instance_count, VAR_USE_MEMORY)
    @app.instance.length.should == added_instance_count
  end

  it "decrease instance count" do
    added_instance_count =  @app.instance.length + VAR_INC_INSTANCE
    @app.scale(added_instance_count, VAR_USE_MEMORY)
    reduced_instance_count = added_instance_count - VAR_REDUCE_INSTANCE
    @app.scale(reduced_instance_count, VAR_USE_MEMORY)
    @app.instance.length.should == reduced_instance_count
  end

  it "add a url for the application to respond to" do
    @app.get_response(:get).body_str.should_not == nil
    @app.get_response(:get).body_str.should =~ /Hello from VCAP!/
    new_url = @app.get_newurl('new')
    @app.map(new_url)
    @app.http_get(new_url).body_str.should =~ /Hello from VCAP!/
  end

  it "remove a url that the application responds to" do
    new_url = @app.get_newurl('new')
    @app.map(new_url)
    @app.http_get(new_url).body_str.should =~ /Hello from VCAP!/
    @app.unmap(new_url)
    #can't access application through the new url
    @app.http_get(new_url).body_str.should =~ /404 Not Found/
    #can access application through the remaining url
    @app.get_response(:get).body_str.should =~ /Hello from VCAP!/
  end

  it "change url that the application responds to" do
    #Add a url for the application to respond to
    new_url = @app.get_newurl('new')
    @app.map(new_url)
    @app.http_get(new_url).body_str.should =~ /Hello from VCAP!/
    #remove original url
    original_url = @app.get_url
    @app.unmap(original_url)
    #can't access application through the original_url
    @app.http_get(original_url).body_str.should  =~ /404 Not Found/
    #can access application through the new url
    @app.http_get(new_url).body_str.should =~ /Hello from VCAP!/
  end

end
