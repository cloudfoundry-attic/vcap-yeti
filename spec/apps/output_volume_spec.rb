require "harness"
require "spec_helper"
include BVT::Spec

describe "An app with a bunch of output", :runtime => true do
  before(:all) { @session = BVT::Harness::CFSession.new }

  with_app "dora"

  it "doesn't die when printing 100MB" do
    before_id = app.get_response(:get, "/id")

    res = app.get_response(:get, "/logspew/104857600")
    res.to_str.should == "Just wrote 104857600 bytes of zeros to the log"

    # Give time for components (i.e. Warden) to react to the output
    # and potentially make bad decisions (like killing the app)
    sleep 10

    after_id = app.get_response(:get, "/id")

    after_id.should == before_id

    res = app.get_response(:get, "/logspew/2")
    res.to_str.should == "Just wrote 2 bytes of zeros to the log"
  end
end
