require 'postfix_admin/error'

require 'date'
require 'postfix_admin/models'

module PostfixAdmin
  class Base
    attr_reader :config

    DEFAULT_CONFIG = {
      "database" => "mysql2://postfix:password@localhost/postfix",
      "aliases" => 30,
      "mailboxes" => 30,
      "maxquota" => 100,
      "scheme" => "CRAM-MD5",
      "passwordhash_prefix" => true
    }.freeze

    def initialize(config)
      @config = {}
      @config[:database]  = config['database']
      @config[:aliases]   = config['aliases']   || 30
      @config[:mailboxes] = config['mailboxes'] || 30
      @config[:maxquota]  = config['maxquota']  || 100
      @config[:scheme]    = config['scheme']    || 'CRAM-MD5'
      @config[:passwordhash_prefix] = if config['passwordhash_prefix'].nil?
                                        true
                                      else
                                        config['passwordhash_prefix']
                                      end
    end

    def db_setup
      unless @config[:database]
        raise_error "'database' parameter is required in '#{CLI.config_file}'"
      end

      database = ENV.fetch("DATABASE_URL") { @config[:database] }
      uri = URI.parse(database)

      if uri.scheme == "mysql"
        uri.scheme = "mysql2"
        warn("Deprecation Warning: Use 'mysql2' as a DB adopter instead of 'mysql' in '#{CLI.config_file}'")
      end

      if uri.scheme != "mysql2"
        raise_error "'#{uri.scheme}' is not supported as a DB adopter. Use 'mysql2' instead in '#{CLI.config_file}'."
      end

      ActiveRecord::Base.establish_connection(uri.to_s)

    rescue LoadError => e
      raise_error e.message
    end

    def add_admin_domain(user_name, domain_name)
      admin_domain_check(user_name, domain_name)

      admin  = Admin.find(user_name)
      domain = Domain.find(domain_name)

      if admin.has_domain?(domain)
        raise_error "Admin '#{user_name}' has already been registered for Domain '#{domain_name}'"
      end

      admin.rel_domains << domain
      admin.save || raise_error("Relation Error: Domain of Admin")
    end

    def delete_admin_domain(user_name, domain_name)
      admin_domain_check(user_name, domain_name)

      admin = Admin.find(user_name)
      domain_admin_query = admin.domain_admins.where(domain: domain_name)

      unless domain_admin_query.take
        raise_error "#{user_name} is not registered as admin of #{domain_name}."
      end

      domain_admin_query.delete_all
    end

    def add_admin(username, password)
      validate_password(password)

      if Admin.exists?(username)
        raise_error "Admin has already been registered: #{username}"
      end

      admin = Admin.new
      admin.attributes = {
        username: username,
        password: password
      }

      unless admin.save
        raise_error "Failed to save Admin #{admin.errors.map(&:to_s).join}"
      end
    end

    # Adds an email account that consists of a Mailbox and an Alias.
    def add_account(address, password, in_name = nil)
      validate_account(address, password)

      local_part, domain_name = address_split(address)

      domain = find_domain(domain_name)

      name = in_name || ''
      attributes = {
        username: address,
        password: password,
        name: name,
        local_part: local_part,
        quota_mb: @config[:maxquota]
      }

      # An Alias also will be added when a Mailbox is saved.
      mailbox = Mailbox.new(attributes)

      domain.rel_mailboxes << mailbox

      unless domain.save
        raise_error "Failed to save Mailbox and Domain #{mailbox.errors.map(&:to_s).join} #{domain.errors.map(&:to_s).join}"
      end
    end

    def add_alias(address, goto)
      if Mailbox.exists?(address)
        raise_error "Mailbox has already been registered: #{address}"
      end

      alias_must_not_exist!(address)

      local_part, domain_name = address_split(address)

      domain = find_domain(domain_name)

      attributes = {
        local_part: local_part,
        goto: goto
      }

      domain.rel_aliases << Alias.new(attributes)
      domain.save || raise_error("Failed to save Alias")
    end

    def delete_alias(address)
      if Mailbox.exists?(address)
        raise_error "Can not delete mailbox by delete_alias. Use delete_account"
      end

      unless Alias.exists?(address)
        raise_error "#{address} is not found!"
      end

      Alias.where(address: address).delete_all
    end

    def add_domain(domain_name)
      domain_name = domain_name.downcase

      unless valid_domain_name?(domain_name)
        raise_error "Invalid domain name: #{domain_name}"
      end

      if Domain.exists?(domain_name)
        raise_error "Domain has already been registered: #{domain_name}"
      end

      domain = Domain.new
      domain.attributes = {
        domain: domain_name,
        description: domain_name,
        aliases: @config[:aliases],
        mailboxes: @config[:mailboxes],
        maxquota: @config[:maxquota]
      }
      domain.save!
    end

    def delete_domain(domain_name)
      domain_name = domain_name.downcase

      domain = find_domain(domain_name)

      admin_names = domain.admins.map(&:username)

      domain.destroy!

      # Remove admins who had the deleted domain only
      admin_names.each do |name|
        next unless Admin.exists?(name)

        admin = Admin.find(name)

        # check if the admin is needed or not
        if admin.rel_domains.empty?
          admin.destroy!
        end
      end
    end

    def delete_admin(user_name)
      unless Admin.exists?(user_name)
        raise_error "Could not find admin #{user_name}"
      end

      admin = Admin.find(user_name)
      admin.rel_domains.delete_all
      admin.destroy!
    end

    def delete_account(address)
      unless Alias.exists?(address) && Mailbox.exists?(address)
        raise_error "Could not find account #{address}"
      end

      Mailbox.where(username: address).delete_all
      Alias.where(address: address).delete_all
    end

    private

    def find_domain(domain_name)
      domain_must_exist!(domain_name)
      Domain.find(domain_name)
    end

    def raise_error(message)
      raise PostfixAdmin::Error, message
    end

    def address_split(address)
      address.split('@')
    end

    def valid_domain_name?(domain_name)
      /.+\..+/.match?(domain_name)
    end

    def valid_email_address?(address)
      /.+@.+\..+/.match?(address)
    end

    def domain_must_exist!(domain_name)
      unless Domain.exists?(domain_name)
        raise_error "Could not find domain: #{domain_name}"
      end
    end

    def alias_must_not_exist!(address)
      if Alias.exists?(address)
        raise_error "Alias has already been registered: #{address}"
      end
    end

    def admin_domain_check(user_name, domain_name)
      unless Admin.exists?(user_name)
        raise_error "#{user_name} is not registered as admin."
      end

      domain_must_exist!(domain_name)
    end

    def validate_password(password)
      raise_error "Empty password" if password.nil? || password.empty?
    end

    def validate_account(address, password)
      validate_password(password)

      unless valid_email_address?(address)
        raise_error "Invalid email address: #{address}"
      end

      alias_must_not_exist!(address)
    end
  end
end
