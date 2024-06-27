require "test_helper"
require "postfix_admin/runner"

class RunnerTest < ActiveSupport::TestCase
  setup do
    db_reset
    @domain = create(:domain, domain: "example.test")
    @domain.admins << build(:admin, username: "admin@example.test")
    @domain.rel_aliases   << build(:alias, address: "alias@example.test")
    @domain.rel_aliases   << build(:alias, address: "user@example.test")
    @domain.rel_mailboxes << build(:mailbox, local_part: "user")
    @domain.save!
  end

  test "#add_alias adds an Alias" do
    assert_difference("Alias.count") do
      res = capture { Runner.start(%w[add_alias new_alias@example.test goto@example2.test]) }
      assert_match '"new_alias@example.test: goto@example2.test" was successfully registered as an alias', res
    end
    assert Alias.exists?("new_alias@example.test")
    new_alias = Alias.find("new_alias@example.test")
    assert_equal "goto@example2.test", new_alias.goto
  end

  test "#add_alias can not add an Alias for an existing Mailbox with the same address" do
    res = exit_capture { Runner.start(%w[add_alias user@example.test goto@example2.test]) }
    assert_match "Mailbox has already been registered: user@example.test", res
  end

  test "#delete_alias deletes an Alias" do
    assert Alias.exists?("alias@example.test")
    assert_difference("Alias.count", -1) do
      res = capture { Runner.start(%w[delete_alias alias@example.test]) }
      assert_match '"alias@example.test" was successfully deleted', res
    end
    assert_not Alias.exists?("alias@example.test")
  end

  test "#delete_alias can not delete an Alias that belongs to a Mailbox" do
    res = exit_capture { Runner.start(%w[delete_alias user@example.test]) }
    assert_match "Can not delete mailbox by delete_alias", res
  end
end
