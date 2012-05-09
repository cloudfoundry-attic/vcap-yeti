require "harness"
require "spec_helper"

describe BVT::Spec::UsersManagement::AdminUser do

  before(:each) do
    @admin_session = BVT::Harness::CFSession.new(true)
    @test_email = "#{@admin_session.namespace}my_fake@email.address"
  end

  after(:each) do
    test_user = @admin_session.user(@test_email)
    test_user.delete
  end

  it "test add-user/users/delete-user/passwd command", :admin => true do
    # create user
    test_user = @admin_session.user(@test_email)
    test_pwd = "test-pwd"
    test_user.create(test_pwd)
    @admin_session.users.collect(&:email).include?(test_user.email).should \
      be_true, "cannot find created user-email, #{test_user.email}"

    # login as created user
    test_session= BVT::Harness::CFSession.new(false, test_user.email, test_user.passwd)

    # change passwd
    test_user = test_session.user(@test_email)
    new_passwd = "new_P@ssw0rd"
    test_user.change_passwd(new_passwd)

    # login as new passwd
    test_session = BVT::Harness::CFSession.new(false, test_user.email, new_passwd)
  end

end
