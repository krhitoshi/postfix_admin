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
      @config[:database]  = config["database"]
      @config[:aliases]   = config["aliases"]   || DEFAULT_CONFIG["aliases"]
      @config[:mailboxes] = config["mailboxes"] || DEFAULT_CONFIG["mailboxes"]
      @config[:maxquota]  = config["maxquota"]  || DEFAULT_CONFIG["maxquota"]
      @config[:scheme]    = config["scheme"]    || DEFAULT_CONFIG["scheme"]
      @config[:passwordhash_prefix] = if config.has_key?("passwordhash_prefix")
                                        config["passwordhash_prefix"]
                                      else
                                        DEFAULT_CONFIG["passwordhash_prefix"]
                                      end
    end

    def db_setup
      database = ENV.fetch("DATABASE_URL") { @config[:database] }

      unless database
        raise_error "'database' parameter is required in '#{CLI.config_file}' or specify 'DATABASE_URL' environment variable"
      end

      uri = URI.parse(database)

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

      raise_save_error(admin) unless admin.save
    end

    # Adds an email account that consists of a Mailbox and an Alias.
    def add_account(address, password, name: "")
      validate_account(address, password)

      local_part, domain_name = address_split(address)
      domain_must_exist!(domain_name)

      attributes = {
        local_part: local_part,
        domain: domain_name,
        password: password,
        name: name,
        quota_mb: @config[:maxquota]
      }

      # An Alias also will be added when a Mailbox is saved.
      mailbox = Mailbox.new(attributes)

      raise_save_error(mailbox) unless mailbox.save
    end

    def add_alias(address, goto)
      if Mailbox.exists?(address)
        raise_error "Mailbox has already been registered: #{address}"
      end

      alias_must_not_exist!(address)

      local_part, domain_name = address_split(address)

      domain = find_domain(domain_name)

      attributes = {
        address: address,
        goto: goto
      }

      domain.rel_aliases << Alias.new(attributes)

      raise_save_error(domain) unless domain.save
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

    def add_domain(domain_name, description: nil)
      domain_name = domain_name.downcase

      unless valid_domain_name?(domain_name)
        raise_error "Invalid domain name: #{domain_name}"
      end

      if Domain.exists?(domain_name)
        raise_error "Domain has already been registered: #{domain_name}"
      end

      new_description = description || domain_name

      domain = Domain.new
      domain.attributes = {
        domain: domain_name,
        description: new_description,
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
    end

    def delete_admin(user_name)
      unless Admin.exists?(user_name)
        raise_error "Could not find admin #{user_name}"
      end

      admin = Admin.find(user_name)
      admin.destroy!
    end

    def delete_account(address)
      unless Alias.exists?(address) && Mailbox.exists?(address)
        raise_error "Could not find account: #{address}"
      end

      mailbox = Mailbox.find(address)
      mailbox.destroy!
    end

    private

    def find_domain(domain_name)
      domain_must_exist!(domain_name)
      Domain.find(domain_name)
    end

    def raise_error(message)
      raise PostfixAdmin::Error, message
    end

    def raise_save_error(obj)
      raise_error "Failed to save #{obj.class}: #{obj.errors.full_messages.join(', ')}"
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
