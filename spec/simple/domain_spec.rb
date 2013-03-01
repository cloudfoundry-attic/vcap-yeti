require "harness"
require "spec_helper"
require "cfoundry"

include BVT::Spec

describe "Simple::Domain" do

  before(:all) do
    @session = BVT::Harness::CFSession.new
    pending("cloud controller v1 API does not support custom domain") unless @session.v2?
  end

  before do
    @original_space = @session.current_space
  end

  after do
    @session.select_org_and_space("", @original_space.name)
  end

  it "create and delete custom domain" do
    @org_name = @session.current_organization.name
    new_name = 'new-domain.com'
    domain = @session.domain(new_name)

    domain.create
    domain.check_domain_of_org.should be_true, "domain: #{domain.name} does not exist in org: #{@org_name}."

    domain.delete
    domain.check_domain_of_org.should be_false, "domain: #{domain.name} is not successfully deleted from org: #{@org_name}."
  end

  it "create and delete multiple custom domains" do
    #create multiple custom domains
    domain_array = []
    10.times do |i|
      new_name = 'new-domain' + i.to_s + '.com'
      domain = @session.domain(new_name)
      domain.create
      domain_array << domain.name
      domain.check_domain_of_org.should == true
    end

    #delete multiple custom domains and verify deletion
    domains = @session.domains
    domains.each{ |s|
      domain_array.each do |item|
        if s.name == item
          s.delete
          s.check_domain_of_org.should == false
        end
      end
    }
  end

  it "create duplicated custom domain(negative testing)" do
    new_name = 'new-domain.com'
    domain = @session.domain(new_name)

    domain.create
    domain.check_domain_of_org.should == true

    lambda {domain.create}.should raise_error(RuntimeError, /The domain name is taken/)

    domain.delete
    domain.check_domain_of_org.should == false
  end

  it "add and delete custom domain" do
    @org_name = @session.current_organization.name
    new_name = 'new-domain.com'
    domain = @session.domain(new_name)

    new_domain = domain.create
    domain.check_domain_of_org.should be_true, "domain: #{domain.name} does not exist in org: #{@org_name}."

    domain.add(new_domain)
    domain.check_domain_of_space.should be_true, "domain: #{domain.name} does not exist in space: #{@session.current_space.name}."

    domain.delete
    domain.check_domain_of_space.should be_false, "domain: #{domain.name} is not successfully deleted from space: #{@session.current_space.name}."
  end

  it "add and delete multiple custom domains" do
    #add multiple custom domains
    domain_array = []
    10.times do |i|
      new_name = 'new-domain' + i.to_s + '.com'
      domain = @session.domain(new_name)
      new_domain = domain.create
      domain.check_domain_of_org.should == true
      domain.add(new_domain)
      domain_array << domain.name
      domain.check_domain_of_space.should == true
    end

    #delete multiple custom domains of space and verify deletion
    space = @session.current_space
    domains = space.domains.collect {|domain| BVT::Harness::Domain.new(domain, @session)}
    domains.each{ |s|
      domain_array.each do |item|
        if s.name == item
          s.delete
          s.check_domain_of_org.should == false
        end
      end
    }

  end

  it "list domains in one space" do
    #create one space & setting this space as current space
    #record current space before we set new current space, so that we can reset back
    previous_space = @session.current_space
    space = @session.space("domain-space")
    space.create
    @session.select_org_and_space("",space.name)
    space = @session.current_space
    space.name.should == space.name
    harness_space = BVT::Harness::Space.new(space, @session)

    #add newly-created custom domain into this space
    target_domain = @session.get_target_domain
    domain_array = [ target_domain ]
    10.times do |i|
      new_name = 'new-domain' + i.to_s + '.com'
      domain = @session.domain(new_name)
      new_domain = domain.create
      domain.check_domain_of_org.should == true
      domain.add(new_domain)
      domain_array << domain.name
    end

    #list domains of this space
    domains = space.domains
    domains_list = [ ]
    domains.each{ |s|
      domains_list = domains_list + [ s.name ]
    }

    #check if domains of this space are list correctly
    domains_list.sort!
    domain_array.sort!
    domains_list.should == domain_array

    #delete multiple custom domains of space
    domains = space.domains.collect {|domain| BVT::Harness::Domain.new(domain, @session)}
    domains.each{ |s|
      domain_array.each do |item|
        if (s.name != target_domain ) and (s.name == item )
          s.delete
          s.check_domain_of_org.should == false
        end
      end
    }

    #delete space
    harness_space.delete

    #reset back to previous space
    @session.select_org_and_space("",previous_space.name)
    space = @session.current_space
    space.name.should == previous_space.name
  end

  it "push app to one custom domain" do
    new_name = 'new-domain.com'
    domain = @session.domain(new_name)

    new_domain = domain.create
    domain.check_domain_of_org.should == true

    domain.add(new_domain)
    domain.check_domain_of_space.should == true

    app = create_push_app("simple_app", '', new_domain.name)

    #check if app is successfully pushed to custom domain
    expected_url = app.name + "." + new_domain.name
    app.stats["0"][:state].should == "RUNNING"
    app.stats["0"][:stats][:uris][0].should == expected_url

    #clean up app, domain
    app.delete
    domain.delete
  end

  it "delete custom domain with apps(negative testing)" do
    new_name = 'negative-domain.com'
    domain = @session.domain(new_name)

    new_domain = domain.create
    domain.check_domain_of_org.should == true

    domain.add(new_domain)
    domain.check_domain_of_space.should == true

    app = create_push_app("simple_app", '', new_domain.name)

    lambda {domain.delete}.should raise_error(RuntimeError, /The request is invalid/)
    domain.check_domain_of_org.should == true

    #clean up app, domain
    app.delete
    domain.delete
  end

  it "delete custom domain that was ever bound with app" do
    #add custom domain in one space
    new_name = 'new-domain.com'
    domain = @session.domain(new_name)
    new_domain = domain.create
    domain.add(new_domain)
    domain.check_domain_of_space.should == true

    #push app into the custom domain
    app = create_push_app("simple_app", '', new_domain.name)
    app.stats["0"][:state].should == "RUNNING"

    #delete app
    app.delete

    #delete custom domain and check if the domain can be successfully deleted.
    domain.delete
    domain.check_domain_of_org.should == false
  end

  it "remove custom domain" do
    #create one space & setting this space as current space
    @space = @session.space("domain-space")
    @space.create
    @session.select_org_and_space("", @space.name)
    current_space = @session.current_space
    current_space.name.should == @space.name

    #create newly-created custom domain
    new_name = 'new-domain.com'
    domain = @session.domain(new_name)
    new_domain = domain.create
    domain.check_domain_of_org.should be_true, "domain: #{domain.name} does not exist in org: #{@org_name}."

    #add newly-created custom domain into the space
    domain.add(new_domain)
    domain.check_domain_of_space.should be_true, "domain: #{domain.name} does not exist in space: #{@session.current_space.name}."
    harness_space = BVT::Harness::Space.new(current_space, @session)
    harness_space.remove_domain(domain)

    #check if the domain is removed from the space
    domain.check_domain_of_space.should be_false, "domain: #{domain.name} is not successfully removed from space: #{@session.current_space.name}."
    domain.check_domain_of_org.should be_true, "domain: #{domain.name} should not be removed from org: #{@org_name}."

    #clean up domain, space
    domain.delete
    harness_space.delete
  end

  it "app can be bound to the routes based of custom domain" do
    #add multiple custom domains
    num_domain = 4
    domain_array = []
    num_domain.times do |i|
      new_name = "new-domain#{i + 5}.com"
      domain = @session.domain(new_name)
      new_domain = domain.create
      domain.check_domain_of_org.should == true
      domain.add(new_domain)
      domain_array << domain.name
      domain.check_domain_of_space.should == true
    end

    #push app into one new domain and check if app is successfully pushed to custom domain
    app = create_push_app("simple_app", '', domain_array[0])
    expected_url = app.name + "." + domain_array[0]
    app.stats["0"][:state].should == "RUNNING"
    app.stats["0"][:stats][:uris][0].should == expected_url

    #map this app to other custom domains
    domain_array.each { |d| app.map("#{app.name}.#{d}")}

    #check route list
    routes = @session.client.routes.select { |r| r.host == app.name }
    routes.length.should == num_domain

    #clean up
    domain_array.each { |d| app.unmap("#{app.name}.#{d}", :delete => true) }

    #clean up app, domain
    app.delete

    #delete multiple custom domains of space and verify deletion
    space = BVT::Harness::Space.new(@session.current_space, @session)
    domains = @session.current_space.domains.collect {|domain| BVT::Harness::Domain.new(domain, @session)}

    domains.each do |d|
      domain_array.each do |item|
        if d.name == item
          space.remove_domain(d)
          d.delete
          d.check_domain_of_org.should == false
        end
      end
    end
  end
end
