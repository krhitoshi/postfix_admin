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
end
