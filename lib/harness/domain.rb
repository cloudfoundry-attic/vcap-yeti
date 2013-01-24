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
        @domain
      rescue Exception => e
        @log.error("Fail to create domain (#{@domain.name} ) " +
                       "\n#{e.to_s}")
        raise RuntimeError, "Fail to create domain (#{@domain.name} )" +
            "\n#{e.to_s}\n#{@session.print_client_logs}"
      end
    end

    def add(domain)
      org = @session.current_organization
      space = @session.current_space

      @log.info("Add Domain ( #{domain} ) in space ( #{space.name} ) of organization ( #{org.name} )")
      begin
        space.add_domain(domain)
      rescue Exception => e
        @log.error("Fail to add domain (#{domain} )" +
                       "\n#{e.to_s}")
        raise RuntimeError, "Fail to add domain (#{domain} ) " +
            "\n#{e.to_s}\n#{@session.print_client_logs}"
      end
    end

    def check_domain_of_space
      space = @session.current_space

      domains = space.domains
      match = false
      domains.each{ |s|
        match = true if s.name == @name
      }
      match
    end

    def check_domain_of_org
      domains = @session.domains
      match = false
      domains.each{ |s|
        match = true if s.name == @name
      }
      match
    end

    def delete
      if @domain.exists?
        @log.info("Delete Domain (#{@domain.name}) ")

        begin
          @domain.delete!
        rescue Exception => e
          @log.error("Fail to delete domain ( #{@domain.name} )" )
          raise RuntimeError, "Fail to delete domain ( #{@domain.name} )" +
              "\n#{e.to_s}\n#{@session.print_client_logs}"
        end
      end
    end

  end
end
