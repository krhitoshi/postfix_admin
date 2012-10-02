require 'thor'
require 'postfix_admin'
require 'postfix_admin/cli'

module PostfixAdmin
  class Runner < Thor
    def initialize(*args)
      super
      @cli = CLI.new
    end

    desc "summary", "Summarize the usage of PostfixAdmin"
    def summary
      runner do
        @cli.show_summary
      end
    end

    desc "show", "List of domains"
    def show(domain=nil)
      runner do
        @cli.show(domain)
      end
    end

    desc "setup example.com password", "Setup a domain"
    def setup_domain(domain, password)
      runner do
        @cli.setup_domain(domain, password)
      end
    end

    desc "add_domain example.com", "Add a domain"
    def add_domain(domain)
      runner do
        @cli.add_domain(domain)
      end
    end

    desc "delete_domain example.com", "Delete a domain"
    def delete_domain(domain)
      runner do
        @cli.delete_domain(domain)
      end
    end

    desc "delete_admin admin@example.com", "Delete an admin"
    def delete_admin(user_name)
      runner do
        @cli.delete_admin(user_name)
      end
    end

    desc "delete_account user@example.com", "Delete an account"
    def delete_account(address)
      runner do
        @cli.delete_account(address)
      end
    end

    desc "add_account", "Add an account"
    def add_account(address=nil,password=nil)
      runner do
        @cli.add_account(address, password)
      end
    end

    desc "add_admin", "Add an admin user"
    def add_admin(user_name=nil, password=nil)
      runner do
        @cli.add_admin(user_name, password)
      end
    end

    desc "add_admin_domain", "Add admin_domain"
    def add_admin_domain(user_name=nil, domain=nil)
      runner do
        @cli.add_admin_domain(user_name, domain)
      end
    end

    desc "add_alias alias@example.com goto@example.net", "Add an alias"
    def add_alias(address, goto)
      runner do
        @cli.add_alias(address, goto)
      end
    end

    desc "delete_alias", "Delete an alias"
    def delete_alias(address=nil)
      runner do
        @cli.delete_alias(address)
      end
    end

    desc "version", "Show postfix_admin version"
    def version
      require 'postfix_admin/version'
      say "postfix_admin #{VERSION}"
    end

    private

    def runner
      begin
        yield
      rescue => e
        warn e.message
      end
    end
  end
end
