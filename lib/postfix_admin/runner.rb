require 'thor'
require 'postfix_admin'
require 'postfix_admin/cli'
require 'postfix_admin/doveadm'

module PostfixAdmin
  class Runner < Thor
    def self.exit_on_failure?
      true
    end

    def initialize(*args)
      super
      @cli = CLI.new
    end

    desc "summary [example.com]", "Summarize the usage of PostfixAdmin"
    def summary(domain_name = nil)
      runner { @cli.show_summary(domain_name) }
    end

    desc "schemes", "List all supported password schemes"
    def schemes
      runner { puts PostfixAdmin::Doveadm.schemes.join(' ') }
    end

    desc "show [example.com | admin@example.com | user@example.com]",
         "Display details about domains, admins, or accounts"
    def show(name = nil)
      runner { @cli.show(name) }
    end

    desc "accounts", "List all accounts"
    def accounts
      runner { @cli.show_accounts }
    end

    desc "setup example.com password", "Set up a domain (add a domain and an admin user for it)"
    method_option :scheme, type: :string, aliases: "-s", desc: "password scheme"
    method_option :rounds, type: :string, aliases: "-r", desc: "encryption rounds for BLF-CRYPT, SHA256-CRYPT and SHA512-CRYPT schemes"
    def setup(domain_name, password)
      runner do
        @cli.setup_domain(domain_name, password,
                          scheme: options[:scheme], rounds: options[:rounds])
      end
    end

    desc "teardown example.com", "Tear down a domain (delete a domain and an admin user for it)"
    def teardown(domain_name)
      runner { @cli.teardown_domain(domain_name) }
    end

    desc "admin_passwd admin@example.com new_password",
         "Change the password of an admin user"
    method_option :scheme, type: :string, aliases: "-s", desc: "password scheme"
    method_option :rounds, type: :string, aliases: "-r", desc: "encryption rounds for BLF-CRYPT, SHA256-CRYPT and SHA512-CRYPT schemes"
    def admin_passwd(user_name, password)
      runner do
        @cli.change_admin_password(user_name, password,
                                   scheme: options[:scheme], rounds: options[:rounds])
      end
    end

    desc "account_passwd user@example.com new_password",
         "Change the password of an account"
    method_option :scheme, type: :string, aliases: "-s", desc: "password scheme"
    method_option :rounds, type: :string, aliases: "-r", desc: "encryption rounds for BLF-CRYPT, SHA256-CRYPT and SHA512-CRYPT schemes"
    def account_passwd(user_name, password)
      runner do
        @cli.change_account_password(user_name, password,
                                     scheme: options[:scheme], rounds: options[:rounds])
      end
    end

    desc "add_domain example.com", "Add a new domain"
    method_option :description, type: :string, aliases: "-d", desc: "description"
    def add_domain(domain_name)
      runner { @cli.add_domain(domain_name, description: options[:description]) }
    end

    desc "edit_domain example.com", "Edit a domain"
    method_option :aliases,   type: :numeric, aliases: "-a", desc: "Edit aliases limitation"
    method_option :mailboxes, type: :numeric, aliases: "-m", desc: "Edit mailboxes limitation"
    method_option :maxquota,  type: :numeric, aliases: "-q", desc: "Edit max quota limitation"
    method_option :active, type: :boolean, desc: "Update active status"
    method_option :description, type: :string, aliases: "-d", desc: "Edit description"
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
      runner { @cli.delete_domain(domain_name) }
    end

    desc "delete_admin admin@example.com", "Delete an admin user"
    def delete_admin(user_name)
      runner { @cli.delete_admin(user_name) }
    end

    desc "delete_account user@example.com", "Delete an account"
    def delete_account(address)
      runner { @cli.delete_account(address) }
    end

    desc "add_account user@example.com password", "Add a new account"
    method_option :name,   type: :string, aliases: "-n", desc: "full name"
    method_option :scheme, type: :string, aliases: "-s", desc: "password scheme"
    method_option :rounds, type: :string, aliases: "-r", desc: "encryption rounds for BLF-CRYPT, SHA256-CRYPT and SHA512-CRYPT schemes"
    def add_account(address, password)
      runner do
        if options[:scheme] == 'scheme'
          warn "Specify password scheme"
          help('add_account')
        else
          if options[:name] == 'name'
            warn "Specify name"
            help('add_account')
          else
            @cli.add_account(address, password, name: options[:name],
                             scheme: options[:scheme], rounds: options[:rounds])
          end
        end
      end
    end

    desc "edit_account user@example.com", "Edit an account"
    method_option :goto,  type: :string,  aliases: "-g",
                  desc: "mailboxes, addresses e-mails are delivered to"
    method_option :quota, type: :numeric, aliases: "-q",
                  desc: "quota limitation (MB)"
    method_option :name,  type: :string,  aliases: "-n",
                  desc: "full name"
    method_option :active, type: :boolean,
                  desc: "Update active status"
    def edit_account(address)
      runner do
        if options.size == 0
          warn "Use one or more options."
          help('edit_account')
        else
          if options[:name] == 'name'
            warn "Specify name"
            help('edit_account')
          else
            @cli.edit_account(address, options)
          end
        end
      end
    end

    desc "edit_admin admin@example.com", "Edit an admin user"
    method_option :active, type: :boolean, desc: "Update active status"
    method_option :super, type: :boolean, desc: "Update super admin status"
    def edit_admin(user_name)
      runner do
        if options.size == 0
          warn "Use one or more options."
          help('edit_admin')
        else
          @cli.edit_admin(user_name, options)
        end
      end
    end

    desc "add_admin admin@example.com password", "Add a new admin user"
    method_option :super, type: :boolean, aliases: "-S", desc: "register as a super admin"
    method_option :scheme, type: :string, aliases: "-s", desc: "password scheme"
    method_option :rounds, type: :string, aliases: "-r", desc: "encryption rounds for BLF-CRYPT, SHA256-CRYPT and SHA512-CRYPT schemes"
    def add_admin(user_name, password)
      runner do
        if options[:scheme] == 'scheme'
          warn "Specify password scheme"
          help('add_admin')
        else
          @cli.add_admin(user_name, password,
                         super_admin: options[:super], scheme: options[:scheme],
                         rounds: options[:rounds])
        end
      end
    end

    desc "add_admin_domain admin@example.com example.com",
         "Grant an admin user access to a specific domain"
    def add_admin_domain(user_name, domain_name)
      runner { @cli.add_admin_domain(user_name, domain_name) }
    end

    desc "delete_admin_domain admin@example.com example.com",
         "Revoke an admin user's access to a specific domain"
    def delete_admin_domain(user_name, domain_name)
      runner { @cli.delete_admin_domain(user_name, domain_name) }
    end

    desc "edit_alias alias@example.com", "Edit an alias"
    method_option :goto,  type: :string,  aliases: "-g",
                  desc: "mailboxes, addresses e-mails are delivered to"
    method_option :active, type: :boolean, desc: "Update active status"
    def edit_alias(address)
      runner do
        if options.size == 0
          warn "Use one or more options."
          help('edit_alias')
        else
          @cli.edit_alias(address, options)
        end
      end
    end

    desc "add_alias alias@example.com goto@example.net", "Add a new alias"
    def add_alias(address, goto)
      runner { @cli.add_alias(address, goto) }
    end

    desc "delete_alias alias@example.com", "Delete an alias"
    def delete_alias(address)
      runner { @cli.delete_alias(address) }
    end

    desc "log", "Display action logs"
    method_option :domain, type: :string, aliases: "-d", desc: "Filter by domain"
    method_option :last,   type: :numeric, aliases: "-l", desc: "Display the last N lines"
    def log
      runner { @cli.log(domain: options[:domain], last: options[:last]) }
    end

    desc "dump", "Dump all data"
    def dump
      runner { @cli.dump }
    end

    desc "version", "Display the version of postfix_admin"
    def version
      require 'postfix_admin/version'
      runner { say "postfix_admin #{VERSION}" }
    end

    private

    def runner(&block)
      @cli.db_setup
      block.call
    rescue StandardError => e
      abort "Error: #{e.message}"
    end
  end
end
