require 'postfix_admin/models'

require 'date'
require 'data_mapper'

class PostfixAdmin
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
        raise "#{username} is not resistered as admin."
      end
      unless domain_exist?(domain)
        raise "Invalid domain #{domain}!"
      end
      if admin_domain_exist?(username, domain)
        raise "#{username} is already resistered as admin of #{domain}."
      end

      d_domain = Domain.first(:domain => domain)
      d_admin  = Admin.first(:username => username)
      d_admin.domains << d_domain
      d_admin.save or raise "Relation Error"
    end

    def add_admin(username, password)
      if admin_exist?(username)
        raise "#{username} is already resistered as admin."
      end
      admin = Admin.new
      admin.attributes = {
        :username => username,
        :password => password,
        :created  => DateTime.now,
        :modified => DateTime.now
      }
      admin.save
    end

    def add_account(address, password)
      if address !~ /.+\@.+\..+/
        raise "Invalid mail address! #{address}"
      end
      user, domain_name = address.split(/@/)
      path = "#{domain_name}/#{address}/"

      unless domain_exist?(domain_name)
        raise "Invalid domain! #{address}"
      end

      if alias_exist?(address)
        raise "#{address} is already resistered."
      end

      domain = Domain.first(:domain => domain_name)
      mail_alias = Alias.new
      mail_alias.attributes = {
        :address  => address,
        :goto     => address,
        :domain   => domain_name,
        :created  => DateTime.now,
        :modified => DateTime.now
      }
      mail_alias.save

      mailbox = Mailbox.new
      mailbox.attributes = {
        :username => address,
        :password => password,
        :name     => '',
        :maildir  => path,
        :quota    => @config[:mailbox_quota],
        # :local_part => user,
        :created  => DateTime.now,
        :modified => DateTime.now
      }
      domain.has_mailboxes << mailbox
      domain.save or raise "Could not save Domain"
    end

    def add_alias(address, goto)
      if mailbox_exist?(address)
        raise "mailbox #{address} is already registered!"
      end
      if alias_exist?(address)
        raise "alias #{address} is already registered!"
      end
      user, domain = address.split(/@/)
      new_alias = Alias.new
      new_alias.attributes = {
        :address => address,
        :goto    => goto,
        :domain  => domain
      }
      new_alias.save or raise "Can not save Alias"
    end

    def delete_alias(address)
      if mailbox_exist?(address)
        raise "Can not delete mailbox by delete_alias. Use delete_account"
      end
      unless alias_exist?(address)
        raise "#{address} is not found!"
      end
      Alias.all(:address => address).destroy or raise "Can not destroy Alias"
    end

    def add_domain(domain_name)
      if domain_name !~ /.+\..+/
        raise "Ivalid domain! #{domain_name}"
      end
      if domain_exist?(domain_name)
        raise "#{domain_name} is already registered!"
      end
      domain = Domain.new
      domain.attributes = {
        :domain      => domain_name,
        :description => domain_name,
        :aliases     => @config[:aliases],
        :mailboxes   => @config[:mailboxes],
        :maxquota    => @config[:maxquota],
        :transport   => "virtual",
        :backupmx    => 0
      }
      domain.save
    end

    def delete_domain(domain)
      unless domain_exist?(domain)
        raise "#{domain} is not found!"
      end

      Alias.all(:domain => domain).destroy or raise "Cannot destroy Alias"
      d_domain = Domain.first(:domain => domain)
      d_domain.has_mailboxes.destroy or raise "Cannot destroy Mailbox"
      d_domain.domain_admins.destroy or raise "Cannot destroy DomainAdmin"
      delete_unnecessary_admins

      d_domain.destroy or raise "Cannot destroy Domain"
    end

    def delete_admin(user_name)
      unless admin_exist?(user_name)
        raise "admin #{user_name} is not found!"
      end
      admin = Admin.first(:username => user_name)
      admin.domain_admins.destroy or raise "Cannot destroy DomainAdmin"
      admin.destroy or raise "Cannnot destroy Admin"
    end

    def delete_account(address)
      Mailbox.all(:username => address).destroy or raise "Cannnot destroy Mailbox"
      Alias.all(:address => address).destroy or raise "Cannnot destroy Alias"
    end

    def delete_unnecessary_admins
      Admin.unnecessary.destroy or raise "Cannnot destroy Admin"
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
        domain = Domain.first(:domain => domain_name)
        if domain
          domain.has_mailboxes
        else
          []
        end
      else
        Mailbox.all(:order => :username)
      end
    end

    def aliases(domain=nil)
      if domain
        Alias.all(:domain => domain, :order => :address)
      else
        Alias.all(:order => :address)
      end
    end

    def admin_domains(username=nil)
      if username
        Admin.first(:username => username).domains
      else
        nil
      end
    end

    def num_total_aliases(domain=nil)
      aliases(domain).count - mailboxes(domain).count
    end
  end
end
