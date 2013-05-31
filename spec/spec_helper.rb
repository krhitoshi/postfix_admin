
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'postfix_admin'
require 'postfix_admin/cli'


include PostfixAdmin

# [fixtures]
# Domain:
#  ALL
#  example.com
#  example.org
#  non-active.example.com (not active)
#
# Admin:
#  all@example.com   Super Admin
#  admin@example.com
#
# Mailbox, Alias:
#  user@example.com
#
# Alias:
#  alias@example.com -> goto@example.jp

def config_initialize
  CLI.config_file = File.join(File.dirname(__FILE__) , 'postfix_admin.conf')
end

def db_clear
  DomainAdmin.all.destroy
  Mailbox.all.destroy
  Alias.all.destroy
  Domain.all.destroy
  Admin.all.destroy
end

def create_domain(domain_name, active=true)
  domain = Domain.new
  domain.attributes = {
    :domain_name  => domain_name,
    :description  => domain_name,
    :maxaliases   => 30,
    :maxmailboxes => 30,
    :maxquota     => 100,
    :active       => active
  }
  domain.save
end

def create_alias_base(address, goto, active)
  Alias.new.attributes = {
    :address  => address,
    :goto     => goto,
    :active   => active
  }
end

def create_alias(address, active=true)
  create_alias_base(address, 'goto@example.jp', active)
end

def create_mailbox_alias(address, active=true)
  create_alias_base(address, address, active)
end

def create_mailbox(address, in_path=nil, active=true)
  path = in_path || "#{address.split('@').last}/#{address}/"
  Mailbox.new.attributes = {
    :username => address,
    :password => 'password',
    :name     => '',
    :maildir  => path,
    :quota    => 100 * KB_TO_MB,
    # :local_part => user,
    :active  => active
  }
end


def db_initialize
  db_clear

  create_domain('ALL')
  create_domain('example.com')
  create_domain('example.org')
  create_domain('non-active.example.com', false)

  username = "admin@example.com"
  admin = Admin.new
  admin.attributes = {
    :username => username,
    :password => 'password',
  }
  admin.save

  non_active_admin = Admin.new
  non_active_admin.attributes = {
    :username => "non_active_admin@example.com",
    :password => 'password',
    :active => false
  }
  non_active_admin.save

  domain = Domain.find('example.com')
  domain.admins << admin
  domain.save

  all_admin = Admin.new
  all_admin.attributes = {
    :username => 'all@example.com',
    :password => 'password',
  }
  all_admin.save

  all_domain = Domain.find('ALL')
  all_domain.admins << all_admin
  all_domain.save

  address = "user@example.com"
  domain.aliases   << create_alias(address)
  domain.aliases   << create_alias('alias@example.com')
  domain.mailboxes << create_mailbox(address)

  unless domain.save
    raise "Could not save domain"
  end
end

DataMapper.setup(:default, 'sqlite::memory:')
DataMapper.finalize
DataMapper.auto_migrate!
db_initialize
config_initialize

module PostfixAdmin
  class Base

    # without DataMapper setup
    def db_setup(database)
      unless database
        raise ArgumentError
      end
    end
  end
end

EX_DELETED    = /successfully deleted/
EX_REGISTERED = /successfully registered/

RSpec.configure do |config|
  config.before do
    ARGV.replace []
  end

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

  def source_root
    File.join(File.dirname(__FILE__), 'fixtures')
  end

  def destination_root
    File.join(File.dirname(__FILE__), 'sandbox')
  end

  alias :silence :capture
end
