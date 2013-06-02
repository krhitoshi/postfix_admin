require 'postfix_admin/models'
require 'postfix_admin/error'

require 'date'
require 'data_mapper'

module PostfixAdmin
  class Base
    attr_reader :config

    DEFAULT_CONFIG = {
      'database'  => 'mysql://postfix:password@localhost/postfix',
      'aliases'   => 30,
      'mailboxes' => 30,
      'maxquota'  => 100,
      'scheme'    => 'CRAM-MD5',
    }

    def initialize(config)
      db_setup(config['database'])
      @config = {}
      @config[:aliases]   = config['aliases']   || 30
      @config[:mailboxes] = config['mailboxes'] || 30
      @config[:maxquota]  = config['maxquota']  || 100
      @config[:mailbox_quota] = @config[:maxquota] * KB_TO_MB
      @config[:scheme]    = config['scheme']    || 'CRAM-MD5'
    end

    def db_setup(database)
      DataMapper.setup(:default, database)
      DataMapper.finalize
    end

    def add_admin_domain(user_name, domain_name)
      admin_domain_check(user_name, domain_name)

      admin  = Admin.find(user_name)
      if admin.has_domain?(domain_name)
        raise Error, "#{user_name} is already resistered as admin of #{domain_name}."
      end

      domain = Domain.find(domain_name)
      admin.domains << domain
      admin.save or raise "Relation Error: Domain of Admin"
    end

    def delete_admin_domain(user_name, domain_name)
      admin_domain_check(user_name, domain_name)

      admin  = Admin.find(user_name)
      unless admin.has_domain?(domain_name)
        raise Error, "#{user_name} is not resistered as admin of #{domain_name}."
      end

      domain = Domain.find(domain_name)
      admin.domains.delete(domain)
      admin.save or "Could not save Admin"
    end

    def add_admin(username, password)
      password_check(password)

      if Admin.exist?(username)
        raise Error, "#{username} is already resistered as admin."
      end
      admin = Admin.new
      admin.attributes = {
        :username => username,
        :password => password,
      }
      unless admin.save
        raise "Could not save Admin #{admin.errors.map{|e| e.to_s}.join}"
      end
    end

    def add_account(address, password)
      password_check(password)

      if address !~ /.+\@.+\..+/
        raise Error, "Invalid mail address #{address}"
      end
      user, domain_name = address_split(address)
      path = "#{domain_name}/#{address}/"

      unless Domain.exist?(domain_name)
        raise Error, "Could not find domain #{domain_name}"
      end

      if Alias.exist?(address)
        raise Error, "#{address} is already resistered."
      end

      domain = Domain.find(domain_name)
      domain.aliases << Alias.mailbox(address)

      mailbox = Mailbox.new
      mailbox.attributes = {
        :username => address,
        :password => password,
        :name     => '',
        :maildir  => path,
        :quota    => @config[:mailbox_quota],
        :local_part => user,
      }
      domain.mailboxes << mailbox
      unless domain.save
        raise "Could not save Mailbox and Domain #{mailbox.errors.map{|e| e.to_s}.join} #{domain.errors.map{|e| e.to_s}.join}"
      end
    end

    def add_alias(address, goto)
      if Mailbox.exist?(address)
        raise Error, "mailbox #{address} is already registered!"
      end
      if Alias.exist?(address)
        raise Error, "alias #{address} is already registered!"
      end
      user, domain_name = address_split(address)
      unless Domain.exist?(domain_name)
        raise Error, "Invalid domain! #{domain_name}"
      end
      domain = Domain.find(domain_name)

      new_alias = Alias.new
      new_alias.attributes = {
        :address => address,
        :goto    => goto,
      }
      domain.aliases << new_alias
      domain.save or raise "Could not save Alias"
    end

    def delete_alias(address)
      if Mailbox.exist?(address)
        raise Error, "Can not delete mailbox by delete_alias. Use delete_account"
      end
      unless Alias.exist?(address)
        raise Error, "#{address} is not found!"
      end
      Alias.all(:address => address).destroy or raise "Could not destroy Alias"
    end

    def add_domain(domain_name)
      domain_name = domain_name.downcase
      if domain_name !~ /.+\..+/
        raise Error, "Ivalid domain! #{domain_name}"
      end
      if Domain.exist?(domain_name)
        raise Error, "#{domain_name} is already registered!"
      end
      domain = Domain.new
      domain.attributes = {
        :domain_name  => domain_name,
        :description  => domain_name,
        :maxaliases   => @config[:aliases],
        :maxmailboxes => @config[:mailboxes],
        :maxquota     => @config[:maxquota],
      }
      domain.save or raise "Could not save Domain"
    end

    def delete_domain(domain_name)
      domain_name = domain_name.downcase
      unless Domain.exist?(domain_name)
        raise Error, "Could not find domain #{domain_name}"
      end

      domain = Domain.find(domain_name)
      domain.mailboxes.destroy or raise "Could not destroy Mailbox"
      domain.aliases.destroy or raise "Could not destroy Alias"
      admin_names = domain.admins.map{|a| a.username }
      domain.clear_admins

      admin_names.each do |name|
        next unless Admin.exist?(name)
        admin = Admin.find(name)
        admin.destroy or raise "Could not destroy Admin" if admin.domains.empty?
      end
      domain.destroy or raise "Could not destroy Domain"
    end

    def delete_admin(user_name)
      unless Admin.exist?(user_name)
        raise Error, "Could not find admin #{user_name}"
      end
      admin = Admin.find(user_name)
      admin.clear_domains
      admin.destroy or raise "Could not destroy Admin"
    end

    def delete_account(address)
      unless Alias.exist?(address) && Mailbox.exist?(address)
        raise Error, "Could not find account #{address}"
      end

      Mailbox.all(:username => address).destroy or raise "Could not destroy Mailbox"
      Alias.all(:address => address).destroy or raise "Could not destroy Alias"
    end

    def address_split(address)
      address.split('@')
    end

    private

    def admin_domain_check(user_name, domain_name)
      raise Error, "#{user_name} is not resistered as admin." unless Admin.exist?(user_name)
      raise Error, "Could not find domain #{domain_name}"     unless Domain.exist?(domain_name)
    end

    def password_check(password)
      raise Error, "Empty password" if password.nil? || password.empty?
    end
  end
end
