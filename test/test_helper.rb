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

  def capture(stream)
    begin
      stream = stream.to_s
      eval("$#{stream} = StringIO.new")
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
end
