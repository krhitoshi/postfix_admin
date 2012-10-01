require 'data_mapper'

class PostfixAdmin
  class Admin
    include ::DataMapper::Resource
    property :username, String, :key => true
    property :password, String
    property :created, DateTime
    property :modified, DateTime

    has n, :domain_admins, :child_key => :username
    has n, :domains, :model => 'Domain', :through => :domain_admins, :via => :p_domain
    storage_names[:default] = 'admin'

    def self.unnecessary
      all.delete_if do |admin|
        admin.domains.size > 0
      end
    end
  end

  class Domain
    include ::DataMapper::Resource
    property :domain, String, :key => true
    property :aliases, Integer
    property :mailboxes, Integer
    property :maxquota, Integer
    property :transport, String
    property :backupmx, Integer
    property :description, String

    has n, :domain_admins, :child_key => :domain
    has n, :admins, :model => 'Admin', :through => :domain_admins

    has n, :has_mailboxes, :model => 'Mailbox', :child_key => :domain
    has n, :has_aliases, :model => 'Alias', :child_key => :domain
    storage_names[:default] = 'domain'

    def self.find(domain)
      Domain.first(:domain => domain)
    end
  end

  class DomainAdmin
    include ::DataMapper::Resource
    property :created, DateTime, :default => DateTime.now

    belongs_to :p_domain, :model => 'Domain', :child_key => :domain, :key => true
    belongs_to :admin, :model => 'Admin', :child_key => :username, :key => true
    storage_names[:default] = 'domain_admins'
  end

  class Mailbox
    include ::DataMapper::Resource
    property :username, String, :key => true
    property :name, String
    property :password, String
    property :domain, String
    property :maildir, String
    property :quota, Integer
    #  property :local_part, String
    property :created, DateTime, :default => DateTime.now
    property :modified, DateTime, :default => DateTime.now

    belongs_to :p_domain, :model => 'Domain', :child_key => :domain

    storage_names[:default] = 'mailbox'
  end

  class Alias
    include ::DataMapper::Resource
    property :address, String, :key => true
    property :goto, Text
    property :domain, String
    property :created, DateTime, :default => DateTime.now
    property :modified, DateTime, :default => DateTime.now

    belongs_to :p_domain, :model => 'Domain', :child_key => :domain

    storage_names[:default] = 'alias'
  end
end
