# require 'postfix_admin/models'
require 'postfix_admin/error'

require 'date'
require 'data_mapper'
require 'active_record'
require 'postfix_admin/models/application_record'
require 'postfix_admin/models/admin'
require 'postfix_admin/models/domain'
require 'postfix_admin/models/mailbox'
require 'postfix_admin/models/alias'
require 'postfix_admin/models/domain_admin'
require 'postfix_admin/models/log'
require 'postfix_admin/models/mail_domain'
require 'postfix_admin/models/quota'

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
#       if local_part_required?
#         eval <<"EOS"
# class ::PostfixAdmin::Mailbox
#     property :local_part, String
# end
# EOS
#         DataMapper.finalize
#       end
      @config = {}
      @config[:aliases]   = config['aliases']   || 30
      @config[:mailboxes] = config['mailboxes'] || 30
      @config[:maxquota]  = config['maxquota']  || 100
      @config[:scheme]    = config['scheme']    || 'CRAM-MD5'
    end

    def db_setup(database)
      ActiveRecord::Base.establish_connection(database)
      # DataMapper.setup(:default, database)
      # DataMapper.finalize
    end

    def add_admin_domain(user_name, domain_name)
      admin_domain_check(user_name, domain_name)

      admin  = Admin.find(user_name)
      domain = Domain.find(domain_name)

      if admin.has_domain?(domain)
        raise Error, "#{user_name} is already resistered as admin of #{domain_name}."
      end

      admin.rel_domains << domain
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

      if Admin.exists?(username)
        raise Error, "#{username} is already resistered as admin."
      end
      admin = Admin.new
      admin.attributes = {
        username: username,
        password: password,
      }
      unless admin.save
        raise "Could not save Admin #{admin.errors.map(&:to_s).join}"
      end
    end

    def add_account(address, password, in_name=nil)
      name = in_name || ''
      password_check(password)

      if address !~ /.+\@.+\..+/
        raise Error, "Invalid mail address #{address}"
      end
      user, domain_name = address_split(address)
      path = "#{domain_name}/#{address}/"

      unless Domain.exists?(domain_name)
        raise Error, "Could not find domain #{domain_name}"
      end

      if Alias.exists?(address)
        raise Error, "#{address} is already resistered."
      end

      domain = Domain.find(domain_name)

      # mail_alias = Alias.new
      # mail_alias.attributes = { address: address, goto: address }
      #
      # domain.rel_aliases << mail_alias

      attributes = {
          username: address,
          password: password,
          name: name,
          maildir: path,
          local_part: user,
          quota_mb: @config[:maxquota]
      }

      mailbox = Mailbox.new(attributes)

      domain.rel_mailboxes << mailbox

      unless domain.save
        raise "Could not save Mailbox and Domain #{mailbox.errors.map(&:to_s).join} #{domain.errors.map(&:to_s).join}"
      end
    end

    def add_alias(address, goto)
      if Mailbox.exists?(address)
        raise Error, "mailbox #{address} is already registered!"
      end
      if Alias.exists?(address)
        raise Error, "alias #{address} is already registered!"
      end

      local_part, domain_name = address_split(address)

      unless Domain.exists?(domain_name)
        raise Error, "Invalid domain! #{domain_name}"
      end

      domain = Domain.find(domain_name)

      attributes = {
        local_part: local_part,
        goto: goto
      }
      domain.rel_aliases << Alias.new(attributes)
      domain.save or raise "Could not save Alias"
    end

    def delete_alias(address)
      if Mailbox.exists?(address)
        raise Error, "Can not delete mailbox by delete_alias. Use delete_account"
      end
      unless Alias.exists?(address)
        raise Error, "#{address} is not found!"
      end
      Alias.all(address: address).destroy or raise "Could not destroy Alias"
    end

    def add_domain(domain_name)
      domain_name = domain_name.downcase
      if domain_name !~ /.+\..+/
        raise Error, "Ivalid domain! #{domain_name}"
      end
      if Domain.exists?(domain_name)
        raise Error, "#{domain_name} is already registered!"
      end
      domain = Domain.new
      domain.attributes = {
        domain: domain_name,
        description: domain_name,
        aliases: @config[:aliases],
        mailboxes: @config[:mailboxes],
        maxquota: @config[:maxquota],
      }
      domain.save or raise "Could not save Domain"
    end

    def delete_domain(domain_name)
      domain_name = domain_name.downcase
      unless Domain.exists?(domain_name)
        raise Error, "Could not find domain #{domain_name}"
      end

      domain = Domain.find(domain_name)
      domain.rel_mailboxes.delete_all
      domain.rel_aliases.delete_all

      admin_names = domain.admins.map(&:username)

      domain.admins.delete_all

      admin_names.each do |name|
        next unless Admin.exists?(name)

        admin = Admin.find(name)

        # check if the admin is needed or not
        if admin.rel_domains.empty?
          admin.destroy
        end
      end

      domain.destroy
    end

    def delete_admin(user_name)
      unless Admin.exists?(user_name)
        raise Error, "Could not find admin #{user_name}"
      end
      admin = Admin.find(user_name)
      admin.clear_domains
      admin.destroy or raise "Could not destroy Admin"
    end

    def delete_account(address)
      unless Alias.exists?(address) && Mailbox.exists?(address)
        raise Error, "Could not find account #{address}"
      end

      Mailbox.where(username: address).delete_all
      Alias.where(address: address).delete_all
    end

    def address_split(address)
      address.split('@')
    end

    private

    # postfixadmin DB upgrade Number 495 loca_part added
    # def local_part_required?
    #   Config.first.value.to_i >= 495
    # end

    def admin_domain_check(user_name, domain_name)
      raise Error, "#{user_name} is not resistered as admin." unless Admin.exists?(user_name)
      raise Error, "Could not find domain #{domain_name}"     unless Domain.exists?(domain_name)
    end

    def password_check(password)
      raise Error, "Empty password" if password.nil? || password.empty?
    end
  end
end
