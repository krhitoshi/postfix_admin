$LOAD_PATH.push(File.join(__dir__, "..", "lib"))

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

  config.before(:example) do
    db_initialize
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

include PostfixAdmin

def db_initialize
  db_reset
  load File.join(__dir__, "..", "db", "seeds.rb")
end

# common methods for tests and specs

def setup_db_connection
  database = if ENV["CI"]
               "mysql2://root:ScRgkaMz4YwHN5dyxfQj@127.0.0.1:13306/postfix_test"
             else
               "mysql2://root:ScRgkaMz4YwHN5dyxfQj@db:3306/postfix_test"
             end
  ENV["DATABASE_URL"] = database
  ActiveRecord::Base.establish_connection(database)
end

def db_reset
  load File.join(__dir__, "..", "db", "reset.rb")
end

# Returns STDOUT and STDERR without rescuing SystemExit
def capture_base(&block)
  begin
    $stdout = StringIO.new
    $stderr = StringIO.new

    block.call
    out = $stdout.string
    err = $stderr.string
  ensure
    $stdout = STDOUT
    $stderr = STDERR
  end

  [out, err]
end
alias silent capture_base

# Returns STDOUT or STDERR as String suppressing both STDOUT and STDERR.
# Raises StandardError when tests unexpectedly exit.
def capture(stream = :stdout, &block)
  out, err = capture_base do
    block.call
    # Raises SystemExit with STDERR when a test unexpectedly exits.
  rescue SystemExit => e
    message = $stderr.string
    message += e.message
    raise StandardError, message
  end

  case stream
  when :stdout
    out
  when :stderr
    err
  else
    raise "MUST NOT HAPPEN"
  end
end

# Returns STDERR when application exits suppressing STDOUT
def exit_capture(&block)
  _out, err = capture_base do
    block.call
  rescue SystemExit
    # do nothing
  end
  err
end

def parse_table(text)
  inside_table = false
  res = {}
  text.each_line do |line|
    if line.start_with?("+-")
      inside_table = !inside_table
      next
    end

    next unless inside_table
    elems = line.chomp.split("|").map(&:strip)[1..]
    res[elems.first] = elems.last
  end

  res
end

setup_db_connection
# db_initialize

module PostfixAdmin
  class Base
    # without actual db setup
    def db_setup
    end
  end
end

# password: "password"
CRAM_MD5_PASS = '{CRAM-MD5}9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740'
CRAM_MD5_PASS_WITHOUT_PREFIX = '9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740'
BLF_CRYPT_PASS = "{BLF-CRYPT}$2y$05$Nkx/QGy0PMR4CgQhfRDnROfMn4JmU8A2eVxROXTWeHlNnQMYs/Aaq"

CRAM_MD5_NEW_PASS = '{CRAM-MD5}820de4c70957274d41111c5fbcae4c87240c9f047fc56f3e720f103571be6cbc'
CRAM_MD5_NEW_PASS_WITHOUT_PREFIX = '820de4c70957274d41111c5fbcae4c87240c9f047fc56f3e720f103571be6cbc'

EX_DELETED    = /successfully deleted/
EX_REGISTERED = /successfully registered/
EX_UPDATED    = /successfully updated/
EX_MD5_CRYPT  = /^\{MD5-CRYPT\}\$1\$[\.\/0-9A-Za-z]{8}\$[\.\/0-9A-Za-z]{22}$/
EX_MD5_CRYPT_WITHOUT_PREFIX = /^\$1\$[\.\/0-9A-Za-z]{8}\$[\.\/0-9A-Za-z]{22}$/
EX_BLF_CRYPT  = /^\{BLF-CRYPT\}\$2y\$\d\d\$.{53}$/
EX_BLF_CRYPT_ROUNDS_10  = /^\{BLF-CRYPT\}\$2y\$10\$.{53}$/
EX_BLF_CRYPT_ROUNDS_13  = /^\{BLF-CRYPT\}\$2y\$13\$.{53}$/
