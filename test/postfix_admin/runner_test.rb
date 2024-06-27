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

  test "#add_domain adds a new Domain" do
    assert_difference("Domain.count") do
      res = capture { Runner.start(%w[add_domain new-domain.test -d NewDomain]) }
      assert_match '"new-domain.test" was successfully registered as a domain', res
    end
    assert Domain.exists?("new-domain.test")
    assert_equal "NewDomain", Domain.find("new-domain.test").description
  end

  test "#delete_domain deletes a Domain" do
    assert Domain.exists?("example.test")
    assert_difference("Domain.count", -1) do
      res = capture { Runner.start(%w[delete_domain example.test]) }
      assert_match '"example.test" was successfully deleted', res
    end
    assert_not Domain.exists?("example.test")
  end

  test "#delete_admin deletes an Admin" do
    assert Admin.exists?("admin@example.test")
    assert_difference("Admin.count", -1) do
      res = capture { Runner.start(%w[delete_admin admin@example.test]) }
      assert_match '"admin@example.test" was successfully deleted', res
    end
    assert_not Admin.exists?("admin@example.test")
  end

  test "#add_admin_domain adds a DomainAdmin" do
    create(:admin, username: "new-admin@example.test")
    assert_difference("DomainAdmin.count") do
      res = capture do
        Runner.start(%w[add_admin_domain new-admin@example.test example.test])
      end
      expected = '"example.test" was successfully registered as a domain of new-admin@example.test'
      assert_match expected, res
    end
    admin = Admin.find("new-admin@example.test")
    assert admin.rel_domains.exists?("example.test")
  end

  test "#delete_admin_domain deletes a DomainAdmin" do
    admin = Admin.find("admin@example.test")
    assert admin.rel_domains.exists?("example.test")
    assert_difference("DomainAdmin.count", -1) do
      res = capture do
        Runner.start(%w[delete_admin_domain admin@example.test example.test])
      end
      expected = "example.test was successfully deleted from admin@example.test"
      assert_match expected, res
    end
    admin.reload
    assert_not admin.rel_domains.exists?("example.test")
  end

  test "#add_account adds a Mailbox and an Alias" do
    assert_account_difference do
      res = capture { Runner.start(%w[add_account new_account@example.test password]) }
      assert_match '"new_account@example.test" was successfully registered as an account', res
    end
    assert Mailbox.exists?("new_account@example.test")
    assert Alias.exists?("new_account@example.test")
    mailbox = Mailbox.find("new_account@example.test")
    expected = "{CRAM-MD5}9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740"
    assert_equal expected, mailbox.password
  end

  test "#delete_account deletes a Mailbox and an Alias" do
    assert Alias.exists?("user@example.test")
    assert Mailbox.exists?("user@example.test")

    assert_account_difference(-1) do
      assert_nothing_raised do
        res = capture { Runner.start(%w[delete_account user@example.test]) }
        assert_match '"user@example.test" was successfully deleted', res
      end
    end

    assert_not Alias.exists?("user@example.test")
    assert_not Mailbox.exists?("user@example.test")
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
