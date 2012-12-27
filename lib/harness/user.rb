require "cfoundry"

module BVT::Harness
  class User
    attr_reader :email, :passwd

    def initialize(user, session)
      @user = user
      @email = @user.email
      @session = session
      @log = @session.log
    end

    def inspect
      "#<BVT::Harness::User '#@email'>"
    end

    def create(passwd)
      @log.info("Create User: #{@email} via Admin User: #{@session.email}")
      begin
        @session.register(@email, passwd)
        @passwd = passwd
      rescue
        @log.error("Failed to create user: #{@email}")
        raise RuntimeError, "Failed to create user: #{@email}"
      end
    end

    def delete
      @log.info("Delete User: #{@email} via Admin User:#{@session.email}")
      begin
        @user.delete!
      rescue Exception => e
        # if @user has been deleted, ignore the exception
        unless @user
          @log.error("Failed to delete user")
          raise RuntimeError, "Failed to delete user.\n#{e.to_s}"
        end
      end
    end

    def change_passwd(new_passwd)
      @log.info "Change User: #{@email} password, new passwd = #{new_passwd}"
      begin
        @user.password = new_passwd
        @user.update!
      rescue
        @log.error("Fail to change password for user: #{@email}")
        raise RuntimeError,
              "Fail to change passsword for user = #{@email}"
      end
    end
  end
end

