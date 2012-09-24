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
      list = []
      all.each do |admin|
        if admin.domains.count == 0
          list << admin
        end
      end
      list
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
    storage_names[:default] = 'domain'
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
    property :created, DateTime
    property :modified, DateTime

    storage_names[:default] = 'mailbox'
  end

  class Alias
    include ::DataMapper::Resource
    property :address, String, :key => true
    property :goto, Text, :key => true
    property :domain, String
    property :created, DateTime
    property :modified, DateTime

    storage_names[:default] = 'alias'
  end
end
