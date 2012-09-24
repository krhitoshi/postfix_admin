require 'postfix_admin/models'

require 'date'
require 'data_mapper'

class PostfixAdmin::Base
  attr_reader :config

  DEFAULT_CONFIG = {
        'database'  => 'mysql://postfix:password@localhost/postfix',
        'aliases'   => 30,
        'mailboxes' => 30,
        'maxquota'  => 100
  }

  def initialize(config)
    DataMapper.setup(:default, config['database'])
    DataMapper.finalize
    @config = {}
    @config[:aliases]   = config['aliases']   || 30
    @config[:mailboxes] = config['mailboxes'] || 30
    @config[:maxquota]  = config['maxquota']  || 100
    @config[:mailbox_quota] = @config[:maxquota] * 1024 * 1000
  end
  def add_admin_domain(username, domain)
    unless admin_exist?(username)
      raise "Error: #{username} is not resistered as admin."
    end
    unless domain_exist?(domain)
      raise "Error: Invalid domain #{domain}!"
    end
    if admin_domain_exist?(username, domain)
      raise "Error: #{username} is already resistered as admin of #{domain}."
    end

    d_domain = PostfixAdmin::Domain.first(:domain => domain)
    d_admin  = PostfixAdmin::Admin.first(:username => username)
    d_admin.domains << d_domain
    d_admin.save or raise "Error: Relation Error"
  end
  def add_admin(username, password)
    if admin_exist?(username)
      raise "Error: #{username} is already resistered as admin."
    end
    admin = PostfixAdmin::Admin.new
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
      raise "Error: Invalid mail address! #{address}"
    end
    user, domain = address.split(/@/)
    path = "#{domain}/#{address}/"

    unless domain_exist?(domain)
      raise "Error: Invalid domain! #{address}"
    end

    if alias_exist?(address)
      raise "Error: #{address} is already resistered."
    end
    mail_alias = PostfixAdmin::Alias.new
    mail_alias.attributes = {
      :address  => address,
      :goto     => address,
      :domain   => domain,
      :created  => DateTime.now,
      :modified => DateTime.now
    }
    mail_alias.save

    mailbox = PostfixAdmin::Mailbox.new
    mailbox.attributes = {
      :username => address,
      :password => password,
      :name     => '',
      :maildir  => path,
      :quota    => @config[:mailbox_quota],
      :domain   => domain,
      # :local_part => user,
      :created  => DateTime.now,
      :modified => DateTime.now
    }
    mailbox.save
  end
  def add_alias(address, goto)
    if alias_exist?(address)
      goto_text = "#{address},#{goto}"
      mail_alias = PostfixAdmin::Alias.first(:address => address)
      mail_alias.update(:goto => goto_text, :modified => DateTime.now)
    else
      raise "Error: Invalid mail address! #{address}"
    end
  end
  def add_domain(domain_name)
    if domain_name !~ /.+\..+/
      raise "Error: Ivalid domain! #{domain_name}"
    end
    if domain_exist?(domain_name)
      raise "Error: #{domain_name} is already registered!"
    end
    domain = PostfixAdmin::Domain.new
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
      raise "Error: #{domain} is not found!"
    end

    PostfixAdmin::Mailbox.all(:domain => domain).destroy or raise "Error: Cannot destroy Mailbox"
    PostfixAdmin::Alias.all(:domain => domain).destroy or raise "Error: Cannot destroy Alias"
    d_domain = PostfixAdmin::Domain.first(:domain => domain)
    PostfixAdmin::DomainAdmin.all(:domain => domain).destroy or raise "Error: Cannot destroy DomainAdmin"

    unnecessary_admins = PostfixAdmin::Admin.all.find_all do |admin|
      admin.domains.size == 0
    end
    if unnecessary_admins
      unnecessary_admins.each do |admin|
        admin.destroy or raise "Error: Cannnot destroy Admin"
      end
    end

    d_domain.destroy or raise "Error: Cannot destroy Domain"
  end
  def admin_domain_exist?(username, domain)
    PostfixAdmin::DomainAdmin.all(:username => username, :domain => domain).count != 0
  end
  def admin_exist?(admin)
    PostfixAdmin::Admin.all(:username => admin).count != 0
  end
  def alias_exist?(address)
    PostfixAdmin::Alias.all(:address => address).count != 0
  end
  def domain_exist?(domain)
    PostfixAdmin::Domain.all(:domain => domain).count != 0
  end
  def domains
    PostfixAdmin::Domain.all(:domain.not => 'ALL', :order => :domain)
  end
  def admins
    PostfixAdmin::Admin.all(:order => 'username')
  end
  def mailboxes(domain=nil)
    if domain
      PostfixAdmin::Mailbox.all(:domain => domain, :order => :username)
    else
      PostfixAdmin::Mailbox.all(:order => :username)
    end
  end
  def aliases(domain=nil)
    if domain
      PostfixAdmin::Alias.all(:domain => domain, :order => :address)
    else
      PostfixAdmin::Alias.all(:order => :address)
    end
  end
  def admin_domains(username=nil)
    if username
      PostfixAdmin::Admin.first(:username => username).domains
    else
      nil
    end
  end
end
