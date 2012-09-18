require "cfoundry"

module BVT::Harness
  class Space
    attr_reader :name

    def initialize(space, session)
      @space = space
      @name = @space.name unless @space.name.nil?
      @session = session
      @log = @session.log
    end

    def inspect
      "#<BVT::Harness::Space '#@name'>"
    end

    def create
      org = @session.current_organization
      @space.organization = org
      @space.name = @name

      @log.info("Create Space ( #{@space.name} ) in organization ( #{org.name} )")
      begin
        @space.create!
        @space.add_developer @session.client.current_user
      rescue Exception => e
        @log.error("Fail to create space (#{@space.name} " +
                       "\n#{e.to_s}")
        raise RuntimeError, "Fail to create service (#{@space.name} " +
            "\n#{e.to_s}"
      end
    end

    def delete(force = false)
      if @space.exists?
        @log.info("Delete Space (#{@space.name} ")
        apps = @space.apps
        instances = @space.service_instances

        if force == true
          apps.each{ |app| app.delete! } unless apps.empty?
          instances.each{ |instance| instance.delete! } unless instances.empty?
        elsif !apps.empty? || !instances.empty?
          @log.error("Fail to delete space (#{@space.name})")
          raise RuntimeError, "Fail to delete space ( #{@space.name} )" +
              "\nSpace ( #{@space.name} ) is not empty!"
        end

        begin
          @space.delete!
        rescue Exception => e
          @log.error("Fail to delete space ( #{@space.name} )" )
          raise RuntimeError, "Fail to delete space ( #{@space.name} )" +
              "\n#{e.to_s}"
        end
      end
    end

  end
end
