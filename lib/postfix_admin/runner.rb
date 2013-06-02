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
      runner{ @cli.show_summary(domain_name) }
    end

    desc "show [example.com | user@example.com]", "Show domains or mailboxes"
    def show(domain_name=nil)
      runner{ @cli.show(domain_name) }
    end

    desc "setup example.com password", "Setup a domain"
    def setup(domain_name, password)
      runner{ @cli.setup_domain(domain_name, password) }
    end

    desc "super_admin admin@example.com", "Enable super admin flag of an admin"
    method_option :disable, :type => :boolean, :aliases => "-d", :desc => "Disable super admin flag"
    def super_admin(user_name)
      runner{ @cli.super_admin(user_name, options[:disable]) }
    end

    desc "admin_passwd admin@example.com new_password", "Change password of admin"
    def admin_passwd(user_name, password)
      runner{ @cli.change_admin_password(user_name, password) }
    end

    desc "account_passwd user@example.com new_password", "Change password of account"
    def account_passwd(user_name, password)
      runner{ @cli.change_account_password(user_name, password) }
    end

    desc "add_domain example.com", "Add a domain"
    def add_domain(domain_name)
      runner{ @cli.add_domain(domain_name) }
    end

    desc "edit_domain example.com", "Edit a domain limitation"
    method_option :aliases,   :type => :numeric, :aliases => "-a", :desc => "Edit aliases limitation"
    method_option :mailboxes, :type => :numeric, :aliases => "-m", :desc => "Edit mailboxes limitation"
    method_option :maxquota,  :type => :numeric, :aliases => "-q", :desc => "Edit max quota limitation"
    def edit_domain(domain_name)
      runner do
        if options.size == 0
          warn "Use one or more options."
          help('edit_domain')
        else
          @cli.edit_domain(domain_name, options)
        end
      end
    end

    desc "delete_domain example.com", "Delete a domain"
    def delete_domain(domain_name)
      runner{ @cli.delete_domain(domain_name) }
    end

    desc "delete_admin admin@example.com", "Delete an admin"
    def delete_admin(user_name)
      runner{ @cli.delete_admin(user_name) }
    end

    desc "delete_account user@example.com", "Delete an account"
    def delete_account(address)
      runner{ @cli.delete_account(address) }
    end

    desc "add_account user@example.com password", "Add an account"
    method_option :scheme, :type => :string, :aliases => "-s", :desc => "password scheme"
    def add_account(address, password)
      runner{ @cli.add_account(address, password, options) }
    end

    desc "edit_account user@example.com", "Edit an account"
    method_option :quota, :type => :numeric, :aliases => "-q", :desc => "Edit quota limitation"
    def edit_account(address)
      runner do
        if options.size == 0
          warn "Use one or more options."
          help('edit_account')
        else
          @cli.edit_account(address, options)
        end
      end
    end

    desc "add_admin admin@example.com password", "Add an admin user"
    method_option :super, :type => :boolean, :aliases => "-S", :desc => "register as a super admin"
    method_option :scheme, :type => :string, :aliases => "-s", :desc => "password scheme"
    def add_admin(user_name, password)
      runner do
        if options[:scheme] == 'scheme'
          warn "Specify password scheme"
          help('add_admin')
        end
        @cli.add_admin(user_name, password, options[:super], options[:scheme])
      end
    end

    desc "add_admin_domain admin@example.com example.com", "Add admin_domain"
    def add_admin_domain(user_name, domain_name)
      runner{ @cli.add_admin_domain(user_name, domain_name) }
    end

    desc "delete_admin_domain admin@example.com example.com", "Delete admin_domain"
    def delete_admin_domain(user_name, domain_name)
      runner{ @cli.delete_admin_domain(user_name, domain_name) }
    end


    desc "add_alias alias@example.com goto@example.net", "Add an alias"
    def add_alias(address, goto)
      runner{ @cli.add_alias(address, goto) }
    end

    desc "delete_alias alias@example.com", "Delete an alias"
    def delete_alias(address)
      runner{ @cli.delete_alias(address) }
    end

    desc "version", "Show postfix_admin version"
    def version
      require 'postfix_admin/version'
      runner{ say "postfix_admin #{VERSION}" }
    end

    private

    def runner
      begin
        yield
      rescue Error, ArgumentError => e
        warn e.message
      end
    end
  end
end
