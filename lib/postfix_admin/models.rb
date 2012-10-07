require 'data_mapper'

class DateTime
  class << self

    alias org_new new
    def new(year = -4712, mon = 1, mday = 1, hour = 0, min = 0, sec = 0, offset = 0, start = Date::ITALY)
      if year == 0
        nil
      else
        org_new(year, mon, mday, hour, min, sec, offset, start)
      end
    end
  end
end

module PostfixAdmin
  class Admin
    include ::DataMapper::Resource
    property :username, String, :key => true
    property :password, String
    property :created, DateTime, :default => DateTime.now
    property :modified, DateTime, :default => DateTime.now

    has n, :domain_admins, :child_key => :username
    has n, :domains, :model => 'Domain', :through => :domain_admins, :via => :domain
    storage_names[:default] = 'admin'

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

    def self.find(username)
      Admin.first(:username => username)
    end

    def self.exist?(username)
      !!Admin.find(username)
    end

    def self.unnecessary
      all.delete_if do |admin|
        admin.domains.size > 0
      end
    end

    private

    def exist_domain?(domain_name)
      !!domains.first(:domain_name => domain_name)
    end
  end

  class Domain
    include ::DataMapper::Resource
    property :domain_name, String, :field => 'domain', :key => true
    property :maxaliases, Integer, :field => 'aliases'
    property :maxmailboxes, Integer, :field => 'mailboxes'
    property :maxquota, Integer
    property :transport, String, :default => 'virtual'
    property :backupmx, Integer, :default => 0
    property :description, String
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
  end

  class DomainAdmin
    include ::DataMapper::Resource
    property :created, DateTime, :default => DateTime.now
    property :domain_name, String, :field => 'domain', :key => true
    property :username, String, :key => true

    belongs_to :domain, :model => 'Domain', :child_key => :domain_name
    belongs_to :admin, :model => 'Admin', :child_key => :username
    storage_names[:default] = 'domain_admins'
  end

  class Mailbox
    include ::DataMapper::Resource
    property :username, String, :key => true
    property :name, String
    property :domain_name, String, :field => 'domain'
    property :password, String
    property :maildir, String
    property :quota, Integer
    #  property :local_part, String
    property :created, DateTime, :default => DateTime.now
    property :modified, DateTime, :default => DateTime.now

    belongs_to :domain, :model => 'Domain', :child_key => :domain_name

    storage_names[:default] = 'mailbox'

    def self.find(username)
      Mailbox.first(:username => username)
    end

    def self.exist?(username)
      !!Mailbox.find(username)
    end
  end

  class Alias
    include ::DataMapper::Resource
    property :address, String, :key => true
    property :goto, Text
    property :domain_name, String, :field => 'domain'
    property :created, DateTime, :default => DateTime.now
    property :modified, DateTime, :default => DateTime.now

    belongs_to :domain, :model => 'Domain', :child_key => :domain_name

    storage_names[:default] = 'alias'

    def self.find(address)
      Alias.first(:address => address)
    end

    def self.exist?(address)
      !!Alias.find(address)
    end
  end
end
