require "minitest/autorun"
require "active_support"
require "factory_bot"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "..", "lib"))
require "postfix_admin"

class ActiveSupport::TestCase
  include PostfixAdmin
  include FactoryBot::Syntax::Methods

  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  parallelize_setup do |_worker|
    database = ENV.fetch("DATABASE_URL") { 'mysql2://postfix:password@127.0.0.1:13306/postfix' }
    ActiveRecord::Base.establish_connection(database)

    DomainAdmin.delete_all
    Mailbox.delete_all
    Alias.delete_all
    Domain.without_all.delete_all
    Admin.delete_all
  end
end
