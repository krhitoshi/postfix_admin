
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'fileutils'
require 'bundler/setup'
Bundler.require(:default, :development)
require 'postfix_admin'
require 'postfix_admin/cli'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  # config.disable_monkey_patching!

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

include PostfixAdmin

# CRAM-MD5
SAMPLE_PASSWORD = "{CRAM-MD5}9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740"

# [fixtures]
# Domain:
#  ALL
#  example.com
#  example.org
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

def db_clear
  # ::PostfixAdmin::Config.all.destroy
  DomainAdmin.delete_all
  Mailbox.delete_all
  Alias.delete_all
  Domain.without_all.delete_all
  Admin.delete_all
end

def create_domain(domain_name, active = true)
  domain = Domain.new
  domain.attributes = {
    domain: domain_name,
    description: domain_name,
    aliases: 30,
    mailboxes: 30,
    maxquota: 100,
    active: active
  }
  domain.save!
end

def create_alias_base(address, goto, active)
  Alias.new(local_part: address.split("@")[0], goto: goto, active: active)
end

def create_alias(address, active = true)
  create_alias_base(address, 'goto@example.jp', active)
end

def create_mailbox_alias(address, active = true)
  create_alias_base(address, address, active)
end

def create_mailbox(address, in_path = nil, active = true)
  path = in_path || "#{address.split('@').last}/#{address}/"
  Mailbox.new(
    username: address,
    password: SAMPLE_PASSWORD,
    name: '',
    maildir: path,
    quota_mb: 100,
    local_part: address.split('@').first,
    active: active
  )
end

def create_admin(username, active = true)
  admin = Admin.new
  admin.attributes = {
    username: username,
    password: SAMPLE_PASSWORD,
    active: active
  }
  admin.save
  admin
end

# class ::PostfixAdmin::Mailbox
#   property :local_part, String
# end

def db_initialize
  db_clear

  # config = ::PostfixAdmin::Config.new
  # config.attributes = {
  #   :id    => 1,
  #   :name  => "version",
  #   :value => "740"
  # }
  # config.save

  # create_domain('ALL')
  create_domain('example.com')
  create_domain('example.org')

  all_admin = create_admin('all@example.com')
  all_admin.rel_domains << Domain.find('ALL')
  all_admin.superadmin = true if all_admin.has_superadmin_column?
  all_admin.save!

  admin = create_admin('admin@example.com')
  domain = Domain.find('example.com')
  domain.admins << admin
  domain.rel_aliases   << create_alias('alias@example.com')
  domain.rel_aliases   << create_alias('user@example.com')
  domain.rel_mailboxes << create_mailbox('user@example.com')

  domain.save!
end

DATABASE_URL = ENV.fetch("DATABASE_URL") { 'mysql2://postfix:password@127.0.0.1:13306/postfix' }
ActiveRecord::Base.establish_connection(DATABASE_URL)
db_initialize

module PostfixAdmin
  class Base
    # without actual db setup
    def db_setup
    end
  end
end

CRAM_MD5_PASS = '{CRAM-MD5}9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740'
CRAM_MD5_PASS_WITHOUT_PREFIX = '9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740'

CRAM_MD5_NEW_PASS = '{CRAM-MD5}820de4c70957274d41111c5fbcae4c87240c9f047fc56f3e720f103571be6cbc'
CRAM_MD5_NEW_PASS_WITHOUT_PREFIX = '820de4c70957274d41111c5fbcae4c87240c9f047fc56f3e720f103571be6cbc'
EX_DELETED    = /successfully deleted/
EX_REGISTERED = /successfully registered/
EX_UPDATED    = /Successfully updated/
EX_MD5_CRYPT  = /^\{MD5-CRYPT\}\$1\$[\.\/0-9A-Za-z]{8}\$[\.\/0-9A-Za-z]{22}$/
EX_MD5_CRYPT_WITHOUT_PREFIX = /^\$1\$[\.\/0-9A-Za-z]{8}\$[\.\/0-9A-Za-z]{22}$/

RSpec.configure do |config|
  config.before do
    ARGV.replace []
  end

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      $stderr = StringIO.new if stream != "stderr"
      yield
      result = eval("$#{stream}").string
    rescue SystemExit => e
      message = $stderr.string
      message += e.message
      raise message
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

  def exit_capture
    begin
      $stderr = StringIO.new
      yield
    rescue SystemExit => e
    ensure
      result = $stderr.string
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
