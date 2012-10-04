require 'data_mapper'

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

    def super_admin=(value)
      if value
        domains << Domain.find('ALL')
        self.save
      else
        domains(:domain_name => 'ALL').destroy
      end
    end

    def super_admin?
      !!domains.find{ |domain| domain.domain_name == 'ALL' }
    end

    def self.find(username)
      Admin.first(:username => username)
    end

    def self.unnecessary
      all.delete_if do |admin|
        admin.domains.size > 0
      end
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
  end
end
