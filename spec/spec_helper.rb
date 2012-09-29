
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'postfix_admin'

class PostfixAdmin::CLI
  def config_file
    File.join(File.dirname(__FILE__) , 'postfix_admin.conf')
  end
end

# [fixtures]
# example.com
# admin@example.com
# user@example.com

def db_initialize
  domain_name = 'example.com'
  domain = PostfixAdmin::Domain.new
  domain.attributes = {
    :domain      => domain_name,
    :description => domain_name,
    :aliases     => 30,
    :mailboxes   => 30,
    :maxquota    => 100,
    :transport   => "virtual",
    :backupmx    => 0
  }
  domain.save

  username = "admin@#{domain_name}"
  admin = PostfixAdmin::Admin.new
  admin.attributes = {
    :username => username,
    :password => 'password',
    :created  => DateTime.now,
    :modified => DateTime.now
  }
  admin.save

  domain.admins << admin
  domain.save

  address = "user@#{domain_name}"
  mail_alias = PostfixAdmin::Alias.new
  mail_alias.attributes = {
    :address  => address,
    :goto     => address,
    :domain   => domain_name,
    :created  => DateTime.now,
    :modified => DateTime.now
  }
  mail_alias.save

  path = "#{domain_name}/#{address}/"
  mailbox = PostfixAdmin::Mailbox.new
  mailbox.attributes = {
    :username => address,
    :password => 'password',
    :name     => '',
    :maildir  => path,
    :quota    => 100 * 1024 * 1000,
    :domain   => domain_name,
    # :local_part => user,
    :created  => DateTime.now,
    :modified => DateTime.now
  }
  mailbox.save
end

DataMapper.setup(:default, 'sqlite::memory:')
DataMapper.finalize
DataMapper.auto_migrate!
db_initialize

class PostfixAdmin::Base

  # without DataMapper setup
  def db_setup(database)
    unless database
      raise ArgumentError
    end
  end
end

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
