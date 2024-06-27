require "test_helper"

class BaseTest < ActiveSupport::TestCase
  setup do
    db_reset
    @domain = create(:domain, domain: "example.test")
    @domain.admins << build(:admin, username: "admin@example.test")
    @domain.rel_aliases   << build(:alias, address: "alias@example.test")
    @domain.rel_aliases   << build(:alias, address: "user@example.test")
    @domain.rel_mailboxes << build(:mailbox, local_part: "user")
    @domain.save!

    config = { "database" => "mysql2://postfix:password@localhost/postfix" }
    @base = Base.new(config)
  end
end
