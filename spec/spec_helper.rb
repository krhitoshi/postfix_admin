
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

def create_mailbox(address, in_path = nil, active = true)
  path = in_path || "#{address.split('@').last}/#{address}/"
  build(:mailbox, username: address, maildir: path,
                  local_part: address.split('@').first, active: active)
end

def db_initialize
  db_clear

  create(:domain, domain: "example.com")
  create(:domain, domain: "example.org")

  all_admin = create(:admin, username: "all@example.com")
  all_admin.rel_domains << Domain.find('ALL')
  all_admin.superadmin = true if all_admin.has_superadmin_column?
  all_admin.save!

  admin = create(:admin, username: "admin@example.com")
  domain = Domain.find('example.com')
  domain.admins << admin
  domain.rel_aliases   << build(:alias, address: "alias@example.com")
  domain.rel_aliases   << build(:alias, address: "user@example.com")
  domain.rel_mailboxes << create_mailbox('user@example.com')

  domain.save!
end

DATABASE_URL = ENV.fetch("DATABASE_URL") { 'mysql2://postfix:password@127.0.0.1:13306/postfix' }
ActiveRecord::Base.establish_connection(DATABASE_URL)
# db_initialize

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
