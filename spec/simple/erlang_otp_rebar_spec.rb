require "harness"
require "spec_helper"

describe BVT::Spec::Simple::ErlangOtpRebar do
  include BVT::Spec

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
      puts "target cloud has Erlang runtime"
    else
      puts "target cloud does not support Erlang"
      erlang_ready = false
    end

    # figure out if BVT environment has Erlang installed
    begin
      installed_erlang = `erl -version`
    rescue
    end
    if $? != 0
      puts "BVT environment does not have Erlang installed. Please install manually."
      erlang_ready = false
    else
      puts "BVT environment has Erlang runtime installed"
    end

    if !erlang_ready
      pending "Not running Erlang test because the Erlang runtime is not installed"
    else
      path = "../../assets/mochiweb/mochiweb_test"
      Dir.chdir(File.join(File.dirname(__FILE__), path))
      rel_build_result = `make relclean rel`
      raise "Erlang application build failed: #{rel_build_result}" if $? != 0
    end
  end

  it "Deploy Simple Erlang Application" do
    check_erlang_env
    app = create_push_app("mochiweb_test")

    contents = app.get_response(:get)
    contents.should_not == nil
    contents.body_str.should =~ /Hello from VCAP/
    contents.close
  end
end
