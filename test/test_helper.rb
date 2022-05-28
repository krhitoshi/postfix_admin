require "minitest/autorun"
require "active_support"
require "factory_bot"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "..", "lib"))
require "postfix_admin"

class ActiveSupport::TestCase
  include PostfixAdmin
  include FactoryBot::Syntax::Methods

  FactoryBot.find_definitions

  database = ENV.fetch("DATABASE_URL") do
    "mysql2://postfix:password@127.0.0.1:13306/postfix"
  end
  ActiveRecord::Base.establish_connection(database)

  def db_reset
    DomainAdmin.delete_all
    Mailbox.delete_all
    Alias.delete_all
    Domain.without_all.delete_all
    Admin.delete_all
  end

  def assert_account_difference(*args, &block)
    assert_difference(%w[Mailbox.count Alias.count], *args) do
      block.call
    end
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
end
