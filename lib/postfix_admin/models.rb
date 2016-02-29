require 'data_mapper'

module PostfixAdmin
  def self.flag_str(flag)
    flag ? "YES" : "NO"
  end

  class Config
    include ::DataMapper::Resource
    property :id,    Integer, :key => true
    property :name,  String
    property :value, String
    storage_names[:default] = 'config'
  end

  class Admin
    include ::DataMapper::Resource
    property :username, String, :key => true, :length => 0..255
    property :password, String, :length => 0..255
    property :active, Boolean, :default  => true
    property :created, DateTime, :default => DateTime.now
    property :modified, DateTime, :default => DateTime.now

    has n, :domain_admins, :child_key => :username
    has n, :domains, :model => 'Domain', :through => :domain_admins, :via => :domain
    storage_names[:default] = 'admin'

    def active_str
      PostfixAdmin.flag_str(active)
    end

    def has_domain?(domain_name)
      if super_admin?
        Domain.exist?(domain_name)
      else
        exist_domain?(domain_name)
      end
    end

    def super_admin=(value)
      if value
        domains << Domain.find('ALL')
        save or raise "Could not save ALL domain for Admin"
      else
        domain_admins(:domain_name => 'ALL').destroy or raise "Could not destroy DoaminAdmin for Admin"
      end
    end

    def super_admin?
      exist_domain?('ALL')
    end

    def clear_domains
      domains.clear
      save or raise "Could save Admin"
    end

    def self.find(username)
      Admin.first(:username => username)
    end

    def self.exist?(username)
      !!Admin.find(username)
    end

    private

    def exist_domain?(domain_name)
      !!domains.first(:domain_name => domain_name)
    end
  end

  class Domain
    include ::DataMapper::Resource
    property :domain_name, String, :field => 'domain', :key => true, :length => 0..255
    property :maxaliases, Integer, :field => 'aliases'
    property :maxmailboxes, Integer, :field => 'mailboxes'
    property :maxquota, Integer
    property :transport, String, :default => 'virtual', :length => 0..255
    property :backupmx, Integer, :default => 0
    property :description, String, :length => 0..255
    property :active, Boolean, :default  => true
    property :created,  DateTime, :default => DateTime.now
    property :modified, DateTime, :default => DateTime.now

    has n, :domain_admins, :child_key => :domain_name
    has n, :admins, :model => 'Admin', :through => :domain_admins

    has n, :mailboxes, :model => 'Mailbox', :child_key => :domain_name
    has n, :aliases, :model => 'Alias', :child_key => :domain_name
    storage_names[:default] = 'domain'

    def self.all_without_special_domain
      Domain.all(:domain_name.not => 'ALL')
    end

    def self.find(domain)
      Domain.first(:domain_name => domain)
    end

    def self.exist?(domain)
      !!Domain.find(domain)
    end

    def self.num_total_aliases
      Alias.count - Mailbox.count
    end

    def num_total_aliases
      aliases.count - mailboxes.count
    end

    def clear_admins
      admins.clear
      save or raise "Could not save Domain"
    end

    def active_str
      PostfixAdmin.flag_str(active)
    end
  end

  class DomainAdmin
    include ::DataMapper::Resource
    property :created, DateTime, :default => DateTime.now
    property :domain_name, String, :field => 'domain', :key => true, :length => 0..255
    property :username, String, :key => true, :length => 0..255

    belongs_to :domain, :model => 'Domain', :child_key => :domain_name
    belongs_to :admin, :model => 'Admin', :child_key => :username
    storage_names[:default] = 'domain_admins'
  end

  class Mailbox
    include ::DataMapper::Resource
    property :username, String, :key => true, :length => 0..255
    property :name, String, :length => 0..255
    property :domain_name, String, :field => 'domain'
    property :password, String, :length => 0..255
    property :maildir, String, :length => 0..255
    property :quota, Integer
    property :active, Boolean, :default  => true
    property :created, DateTime, :default => DateTime.now
    property :modified, DateTime, :default => DateTime.now

    belongs_to :domain, :model => 'Domain', :child_key => :domain_name

    storage_names[:default] = 'mailbox'
    def active_str
      PostfixAdmin.flag_str(active)
    end

    def self.find(username)
      Mailbox.first(:username => username)
    end

    def self.exist?(username)
      !!Mailbox.find(username)
    end
  end

  class Alias
    include ::DataMapper::Resource
    property :address, String, :key => true, :length => 0..255
    property :goto, Text
    property :domain_name, String, :field => 'domain', :length => 0..255
    property :active, Boolean, :default  => true
    property :created, DateTime, :default => DateTime.now
    property :modified, DateTime, :default => DateTime.now

    belongs_to :domain, :model => 'Domain', :child_key => :domain_name

    storage_names[:default] = 'alias'

    def active_str
      PostfixAdmin.flag_str(active)
    end

    def self.mailbox(address)
      mail_alias = Alias.new
      mail_alias.attributes = {
        :address     => address,
        :goto        => address,
      }
      mail_alias
    end

    def self.find(address)
      Alias.first(:address => address)
    end

    def self.exist?(address)
      !!Alias.find(address)
    end

    def mailbox?
      Mailbox.exist?(address)
    end
  end

  class Log
    include ::DataMapper::Resource
    property :timestamp, DateTime, key: true, default: DateTime.now
    property :username, String, length: 0..255
    property :domain_name, String, field: 'domain', length: 0..255
    property :action, String, length: 0..255
    property :data, Text

    belongs_to :domain, :model => 'Domain', :child_key => :domain_name

    storage_names[:default] = 'log'
  end
end
