require "cfoundry"

module BVT::Harness
  class Domain
    attr_reader :name

    def initialize(domain, session)
      @domain = domain
      @name = @domain.name if @domain.name
      @session = session
      @log = @session.log
    end

    def inspect
      "#<BVT::Harness::Domain '#@name'>"
    end

    def create
      org = @session.current_organization
      @domain.owning_organization = org
      @domain.name = @name

      @log.info("Create Domain ( #{@domain.name} ) in organization ( #{org.name} )")
      begin
        @domain.create!
        @session.test_domains << @domain
        @domain
      rescue Exception => e
        @log.error("Fail to create domain (#{@domain.name} ) \n#{e.to_s}")
        raise
      end
    end

    def add(domain)
      org = @session.current_organization
      space = @session.current_space

      @log.info("Add Domain ( #{domain} ) in space ( #{space.name} ) of organization ( #{org.name} )")
      begin
        space.add_domain(domain)
      rescue Exception => e
        @log.error("Fail to add domain (#{domain} )\n#{e.to_s}")
        raise
      end
    end

    def check_domain_of_space
      @session.current_space.domains.any? { |d| d.name == @name }
    end

    def check_domain_of_org
      @session.domains.any? { |d| d.name == @name }
    end

    def delete
      if @domain.exists?
        @log.info("Delete Domain (#{@domain.name}) ")

        begin
          @domain.delete!
          @session.test_domains.delete(@domain)
        rescue Exception => e
          @log.error("Fail to delete domain ( #{@domain.name} )" )
          raise
        end
      end
    end

  end
end
