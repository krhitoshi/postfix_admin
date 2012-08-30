require 'data_mapper'

class PostfixAdmin
  class Admin
    include ::DataMapper::Resource
    property :username, String, :key => true
    property :password, String
    property :created, DateTime
    property :modified, DateTime

    storage_names[:default] = 'admin'
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

    storage_names[:default] = 'domain'
  end

  class DomainAdmin
    include ::DataMapper::Resource
    property :username, String, :key => true
    property :domain, String, :key => true
    property :created, DateTime

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
