require "harness"
require "spec_helper"
include BVT::Spec

module BVT::Spec
  module AcmHelper
  def new
    @acmbase = ENV['ACM_URL']
    @acmuser = ENV['ACM_USER']
    @acmpass = ENV['ACM_PASSWORD']
    pending "empty acm base url" unless @acmbase && @acmuser && @acmpass
  end

  def login
    @auth_header = {"Authorization" => "Basic " + Base64.encode64("#{@acmuser}:#{@acmpass}").chomp}
    begin
      RestClient.get @acmbase, @auth_header
    rescue => e
      if e.kind_of? (RestClient::ResourceNotFound)
        return 404
      end
    end
    return 200
  end

  def clean_data
    @auth_header = {"Authorization" => "Basic " + Base64.encode64("#{@acmuser}:#{@acmpass}").chomp}
    url = @acmbase + "/objects?name=bvt_test_object"
    body = nil
    begin
      response = RestClient.get url, @auth_header
      body = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    rescue => e
    end

    unless body.nil?
    body.each {|obj_id|
      url = @acmbase + "/objects/#{obj_id}"
      acm_resource = RestClient::Resource.new url, :user => @acmuser, :password => @acmpass, :timeout => 20, :open_timeout => 5
      f = lambda {
        response = 0
        begin
          response = acm_resource.delete
        rescue => e
          if e.kind_of? (RestClient::ResourceNotFound)
            return 404
          else
            return 500
          end
        end
        response.code
      }
      result = f.call
    }
    end

    url = @acmbase + "/permission_sets/bvt_app_space"
    acm_resource = RestClient::Resource.new url, :user => @acmuser, :password => @acmpass, :timeout => 20, :open_timeout => 5
    f = lambda {
      response = 0
      begin
        response = acm_resource.delete
      rescue => e
        if e.kind_of? (RestClient::ResourceNotFound)
          return 404
        else
          return 500
        end
      end
      response.code
    }
    result = f.call

    (1..10).each { |i|
      url = @acmbase + "/users"
      acm_resource = RestClient::Resource.new url + "/bvt_test#{i}", :user => @acmuser, :password => @acmpass, :timeout => 20, :open_timeout => 5
      f = lambda {
        response = 0
        begin
          response = acm_resource.delete
        rescue => e
          if e.kind_of? (RestClient::ResourceNotFound)
            return 404
          end
        end
        response.code
      }
      f.call
    }

    (1..2).each { |i|
      url = @acmbase + "/groups"
      acm_resource = RestClient::Resource.new url + "/g-bvt-group#{i}", :user => @acmuser, :password => @acmpass, :timeout => 20, :open_timeout => 5
      f = lambda {
        response = 0
        begin
          response = acm_resource.delete
        rescue => e
          if e.kind_of? (RestClient::ResourceNotFound)
            return 404
          end
        end
        response.code
      }
      f.call
    }

  end

  def create_permission_set
    url = @acmbase + "/permission_sets"

    permission_set_data = {
      :name => "bvt_app_space",
      :additional_info => "{component => cloud_controller}",
      :permissions => [:bvt_read_appspace.to_s, :bvt_write_appspace.to_s, :bvt_delete_appspace.to_s]
    }.to_json

    acm_resource = RestClient::Resource.new url, :user => @acmuser, :password => @acmpass, :timeout => 20, :open_timeout => 5
    response = acm_resource.post permission_set_data
    return response
  end

  def create_user
    url = @acmbase + "/users"

    (1..10).each { |i|
      acm_resource = RestClient::Resource.new url + "/bvt_test#{i}", :user => @acmuser, :password => @acmpass, :timeout => 20, :open_timeout => 5
      response = acm_resource.post nil
      response.code.should == 200
      response.body.should_not == nil
    }

  end

  def add_user_to_group
    url = @acmbase + "/groups"

    group_data1 = {
      :id => "g-bvt-group1",
      :additional_info => "Developer group",
      :members => ["bvt_test1", "bvt_test3"]
    }.to_json

    acm_resource = RestClient::Resource.new url + "/g-bvt-group1", :user => @acmuser, :password => @acmpass, :timeout => 20, :open_timeout => 5
    response = acm_resource.post group_data1
    response.code.should == 200
    response.body.should_not == nil

    group_data2= {
      :id => "g-bvt-group2",
      :additional_info => "Developer group",
      :members => ["bvt_test1", "bvt_test3", "bvt_test5", "bvt_test7", "bvt_test9"]
    }.to_json

    acm_resource = RestClient::Resource.new url + "/g-bvt-group2", :user => @acmuser, :password => @acmpass, :timeout => 20, :open_timeout => 5
    response = acm_resource.post group_data2
    return response
  end

  def create_object
    url = @acmbase + "/objects"

    object_data = {
      :name => "bvt_test_object",
      :additional_info => {:description => :bvt_test_object}.to_json(),
      :permission_sets => [:bvt_app_space.to_s],
      :acl => {
        :bvt_read_appspace => ["bvt_test2", "bvt_test5", "g-bvt-group2"],
        :bvt_write_appspace => ["bvt_test5"],
        :bvt_delete_appspace => ["g-bvt-group2"]
       }
    }.to_json


    acm_resource = RestClient::Resource.new url, :user => @acmuser, :password => @acmpass, :timeout => 20, :open_timeout => 5
    response = acm_resource.post object_data
    response.code.should == 200
    response.body.should_not == nil
    body = Yajl::Parser.parse(response.body, :symbolize_keys => true)
    @object_id = body[:id]
  end

  def check_user_access
    RestClient.get @acmbase + "/objects/#{@object_id}/access?id=bvt_test2&p=bvt_read_appspace", @auth_header
  end

  def check_group_access
    RestClient.get @acmbase + "/objects/#{@object_id}/access?id=bvt-group2&p=bvt_delete_appspace", @auth_header
  end

  end
end

describe BVT::Spec::AcmManager::Acm do
  include BVT::Spec::AcmHelper

  before(:all) do
    new
  end

  after(:each) do
  end

  it "Test ACM login credentials" do
    response = login
    response.should == 404
  end

  it "Exercise the API" do
    pending "Here is one code issue, waiting for fix"

    clean_data

    response = create_permission_set
    response.code.should == 200
    response.body.should_not == nil

    create_user
    response = add_user_to_group
    response.code.should == 200
    response.body.should_not == nil

    create_object
    response = check_user_access
    response.code.should == 200

    response = check_group_access
    response.code.should == 200

  end

end
