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
      'maxquota'  => 100
    }

    def initialize(config)
      db_setup(config['database'])
      @config = {}
      @config[:aliases]   = config['aliases']   || 30
      @config[:mailboxes] = config['mailboxes'] || 30
      @config[:maxquota]  = config['maxquota']  || 100
      @config[:mailbox_quota] = @config[:maxquota] * 1024 * 1000
    end

    def db_setup(database)
      DataMapper.setup(:default, database)
      DataMapper.finalize
    end

    def add_admin_domain(username, domain)
      unless admin_exist?(username)
        raise Error, "#{username} is not resistered as admin."
      end
      unless domain_exist?(domain)
        raise Error, "Could not find domain #{domain}"
      end
      if admin_domain_exist?(username, domain)
        raise Error, "#{username} is already resistered as admin of #{domain}."
      end

      d_domain = Domain.find(domain)
      d_admin  = Admin.find(username)
      d_admin.domains << d_domain
      d_admin.save or raise "Relation Error: Domain of Admin"
    end

    def add_admin(username, password)
      if admin_exist?(username)
        raise Error, "#{username} is already resistered as admin."
      end
      admin = Admin.new
      admin.attributes = {
        :username => username,
        :password => password,
      }
      admin.save or raise "Could not save Admin"
    end

    def add_account(address, password)
      if address !~ /.+\@.+\..+/
        raise Error, "Invalid mail address #{address}"
      end
      user, domain_name = address_split(address)
      path = "#{domain_name}/#{address}/"

      unless domain_exist?(domain_name)
        raise Error, "Could not find domain #{domain_name}"
      end

      if alias_exist?(address)
        raise Error, "#{address} is already resistered."
      end

      domain = Domain.find(domain_name)
      mail_alias = Alias.new
      mail_alias.attributes = {
        :address  => address,
        :goto     => address,
        :domain   => domain_name,
      }
      domain.has_aliases << mail_alias

      mailbox = Mailbox.new
      mailbox.attributes = {
        :username => address,
        :password => password,
        :name     => '',
        :maildir  => path,
        :quota    => @config[:mailbox_quota],
        # :local_part => user,
      }
      domain.has_mailboxes << mailbox
      domain.save or raise "Could not save Domain"
    end

    def add_alias(address, goto)
      if mailbox_exist?(address)
        raise Error, "mailbox #{address} is already registered!"
      end
      if alias_exist?(address)
        raise Error, "alias #{address} is already registered!"
      end
      user, domain_name = address_split(address)
      unless domain_exist?(domain_name)
        raise Error, "Invalid domain! #{domain_name}"
      end
      domain = Domain.find(domain_name)

      new_alias = Alias.new
      new_alias.attributes = {
        :address => address,
        :goto    => goto,
        :domain  => domain
      }
      domain.has_aliases << new_alias
      domain.save or raise "Could not save Alias"
    end

    def delete_alias(address)
      if mailbox_exist?(address)
        raise Error, "Can not delete mailbox by delete_alias. Use delete_account"
      end
      unless alias_exist?(address)
        raise Error, "#{address} is not found!"
      end
      Alias.all(:address => address).destroy or raise "Could not destroy Alias"
    end

    def add_domain(domain_name)
      if domain_name !~ /.+\..+/
        raise Error, "Ivalid domain! #{domain_name}"
      end
      if domain_exist?(domain_name)
        raise Error, "#{domain_name} is already registered!"
      end
      domain = Domain.new
      domain.attributes = {
        :domain      => domain_name,
        :description => domain_name,
        :aliases     => @config[:aliases],
        :mailboxes   => @config[:mailboxes],
        :maxquota    => @config[:maxquota],
      }
      domain.save or raise "Could not save Domain"
    end

    def delete_domain(domain_name)
      unless domain_exist?(domain_name)
        raise "#{domain_name} is not found!"
      end

      domain = Domain.find(domain_name)
      domain.has_mailboxes.destroy or raise "Could not destroy Mailbox"
      domain.has_aliases.destroy or raise "Could not destroy Alias"
      domain.domain_admins.destroy or raise "Could not destroy DomainAdmin"
      delete_unnecessary_admins

      domain.destroy or raise "Could not destroy Domain"
    end

    def delete_admin(user_name)
      unless admin_exist?(user_name)
        raise "admin #{user_name} is not found!"
      end
      admin = Admin.find(user_name)
      admin.domain_admins.destroy or raise "Could not destroy DomainAdmin"
      admin.destroy or raise "Could not destroy Admin"
    end

    def delete_account(address)
      Mailbox.all(:username => address).destroy or raise "Could not destroy Mailbox"
      Alias.all(:address => address).destroy or raise "Could not destroy Alias"
    end

    def delete_unnecessary_admins
      Admin.unnecessary.destroy or raise "Could not destroy Admin"
    end

    def admin_domain_exist?(username, domain)
      DomainAdmin.all(:username => username, :domain => domain).count != 0
    end

    def admin_exist?(admin)
      Admin.all(:username => admin).count != 0
    end

    def mailbox_exist?(address)
      Mailbox.all(:username => address).count != 0
    end

    def alias_exist?(address)
      Alias.all(:address => address).count != 0
    end

    def account_exist?(address)
      alias_exist?(address) && mailbox_exist?(address)
    end

    def mailbox_exist?(user_name)
      Mailbox.all(:username => user_name).count != 0
    end

    def domain_exist?(domain)
      Domain.all(:domain => domain).count != 0
    end

    def domains
      Domain.all(:domain.not => 'ALL', :order => :domain)
    end

    def admins
      Admin.all(:order => 'username')
    end

    def mailboxes(domain_name=nil)
      if domain_name
        domain = Domain.find(domain_name)
        if domain
          domain.has_mailboxes(:order => :username)
        else
          []
        end
      else
        Mailbox.all(:order => :username)
      end
    end

    def aliases(domain_name=nil)
      if domain_name
        domain = Domain.find(domain_name)
        if domain
          domain.has_aliases(:order => :address)
        else
          []
        end
      else
        Alias.all(:order => :address)
      end
    end

    def admin_domains(username=nil)
      if username
        Admin.find(username).domains
      else
        nil
      end
    end

    def num_total_aliases(domain=nil)
      aliases(domain).count - mailboxes(domain).count
    end

    def address_split(address)
      address.split('@')
    end
  end
end
