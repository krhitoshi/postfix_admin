require 'thor'
require 'postfix_admin'
require 'postfix_admin/cli'

module PostfixAdmin
  class Runner < Thor
    def initialize(*args)
      super
      @cli = CLI.new
    end

    desc "summary [example.com]", "Summarize the usage of PostfixAdmin"
    def summary(domain_name=nil)
      runner do
        @cli.show_summary(domain_name)
      end
    end

    desc "show [example.com]", "List of domains"
    def show(domain=nil)
      runner do
        @cli.show(domain)
      end
    end

    desc "setup example.com password", "Setup a domain"
    def setup(domain, password)
      runner do
        @cli.setup_domain(domain, password)
      end
    end

    desc "super_admin admin@example.com", "Enable super admin flag of an admin"
    method_option :disable, :type => :boolean, :aliases => "-d", :desc => "Disable super admin flag"
    def super_admin(user_name)
      runner do
        @cli.super_admin(user_name, options[:disable])
      end
    end

    desc "admin_passwd admin@example.com new_password", "Change password of admin"
    def admin_passwd(user_name, password)
      runner do
        @cli.change_admin_password(user_name, password)
      end
    end

    desc "account_passwd user@example.com new_password", "Change password of account"
    def account_passwd(user_name, password)
      runner do
        @cli.change_account_password(user_name, password)
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

    desc "add_account user@example.com password", "Add an account"
    def add_account(address, password)
      runner do
        @cli.add_account(address, password)
      end
    end

    desc "add_admin admin@example.com password", "Add an admin user"
    method_option :super, :type => :boolean, :aliases => "-s", :desc => "register as a super admin"
    def add_admin(user_name, password)
      runner do
        @cli.add_admin(user_name, password, options[:super])
      end
    end

    desc "add_admin_domain admin@example.com example.com", "Add admin_domain"
    def add_admin_domain(user_name, domain)
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

    desc "delete_alias alias@example.com", "Delete an alias"
    def delete_alias(address)
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
