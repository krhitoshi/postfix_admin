require "minitest/autorun"
require "active_support"
require "factory_bot"
require "test_helper_base"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "..", "lib"))
require "postfix_admin"

class ActiveSupport::TestCase
  include PostfixAdmin
  include FactoryBot::Syntax::Methods

  FactoryBot.find_definitions

  setup_db_connection

  def assert_account_difference(*args, &block)
    assert_difference(%w[Mailbox.count Alias.count], *args) do
      block.call
    end
  end

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
