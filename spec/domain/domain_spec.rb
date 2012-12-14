require "harness"
require "spec_helper"
require "cfoundry"

include BVT::Spec

describe BVT::Spec::CustomDomain::Domain do

  before(:all) do
    @session = BVT::Harness::CFSession.new
    pending("cloud controller v1 API does not support custom domain") unless @session.v2?
    @org_name = @session.current_organization.name
  end

  after(:each) do
    @session.cleanup!("current")
  end

  it "create and delete custom domain" do
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
    @space = @session.space("domain-space")
    @space.create
    @session.select_org_and_space("",@space.name)
    space = @session.current_space
    space.name.should == @space.name

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

  end

  it "push app to one custom domain" do
    new_name = 'newdomain.com'
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
  end

  it "delete custom domain with apps(negative testing)" do
    new_name = 'negative-domain.com'
    domain = @session.domain(new_name)

    new_domain = domain.create
    domain.check_domain_of_org.should == true

    domain.add(new_domain)
    domain.check_domain_of_space.should == true

    create_push_app("simple_app", '', new_domain.name)

    lambda {domain.delete}.should raise_error(RuntimeError, /The request is invalid/)
    domain.check_domain_of_org.should == true
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

end
