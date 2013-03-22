require "harness"
require "spec_helper"

describe "Users::AdminUser" do

  before(:each) do
    @admin_session = BVT::Harness::CFSession.new(:admin => true)
    @test_email = "my_fake@email.address"
  end

  after(:each) do
    test_user = @admin_session.user(@test_email)
    test_user.delete
  end

  it "test add-user/users/delete-user/passwd command" do
    pending "This test was disabled before. It is still using the old non-UAA workflow."
    # create user
    test_user = @admin_session.user(@test_email)
    test_pwd = "test-pwd"
    test_user.create(test_pwd)
    @admin_session.users.collect(&:email).include?(test_user.email).should \
      be_true, "cannot find created user-email, #{test_user.email}"

    # login as created user
    test_session = BVT::Harness::CFSession.new(:email => test_user.email,
                                               :passwd => test_user.passwd,
                                               :target => @admin_session.TARGET)

    # change passwd
    test_user = test_session.user(test_session.email, :require_namespace => false)
    new_passwd = "new_P@ssw0rd"
    test_user.change_passwd(new_passwd)

    # login as new passwd
    test_session = BVT::Harness::CFSession.new(:email => test_user.email,
                                               :passwd => new_passwd,
                                               :target => @admin_session.TARGET)
  end
end
