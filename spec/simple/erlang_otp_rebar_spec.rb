require "harness"
require "spec_helper"
include BVT::Spec

describe BVT::Spec::Simple::ErlangOtpRebar do

  before(:all) do
    @session = BVT::Harness::CFSession.new
  end

  after(:each) do
    @session.cleanup!
  end

  def check_erlang_env
    erlang_ready = true

    # figure out if cloud has erlang runtime
    runtimes = @session.system_runtimes
    if (runtimes.to_s =~ /erlang/)
      @session.log.info "target cloud has Erlang runtime"
    else
      @session.log.info "target cloud does not support Erlang"
      erlang_ready = false
    end

    # figure out if BVT environment has Erlang installed
    begin
      installed_erlang = `erl -version 2>&1`
    rescue
    end
    if $? != 0
      @session.log.info "BVT environment does not have Erlang installed. Please install manually."
      erlang_ready = false
    else
      @session.log.info "BVT environment has Erlang runtime installed"
    end

    if !erlang_ready
      pending "Not running Erlang test because the Erlang runtime is not installed"
    else
      path = "../../assets/mochiweb/mochiweb_test"
      Dir.chdir(File.join(File.dirname(__FILE__), path))
      rel_build_result = `make relclean rel`
      pending "Erlang application build failed: #{rel_build_result}" if $? != 0
    end
  end

  it "Deploy Simple Erlang Application", :p1 => true do
    check_erlang_env
    app = create_push_app("mochiweb_test")

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.to_str.should =~ /Hello from VCAP/
  end
end
