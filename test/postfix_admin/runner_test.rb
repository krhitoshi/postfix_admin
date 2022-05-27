require "test_helper"
require "postfix_admin/runner"

class RunnerTest < ActiveSupport::TestCase
  setup do
    db_reset
    @domain = create(:domain, domain: "example.test")
    @domain.admins << build(:admin, username: "admin@example.test")
    @domain.save!
  end

  test "usual flow with add/delete methods" do
    assert_nothing_raised do
      silent do
        # Use add_domain subcommand
        Runner.start(%w[add_domain new-domain.test])
        Runner.start(%w[add_admin admin@new-domain.test password])
        Runner.start(%w[add_admin_domain admin@new-domain.test new-domain.test])

        Runner.start(%w[add_account user1@new-domain.test password])
        Runner.start(%w[add_account user2@new-domain.test password])
        Runner.start(%w[delete_domain new-domain.test])

        # Use setup subcommand
        Runner.start(%w[setup new-domain2.test password])
        Runner.start(%w[add_account user1@new-domain2.test password])
        Runner.start(%w[add_account user2@new-domain2.test password])
        Runner.start(%w[delete_domain new-domain2.test])
      end
    end
  end

  test "#version" do
    res = capture { Runner.start(["version"]) }
    assert_match(/postfix_admin \d+\.\d+\.\d/, res)
  end

  test "#summary" do
    res = capture { Runner.start(["summary"]) }
    assert_match "[Summary]", res

    res = capture { Runner.start(%w[summary example.test]) }
    assert_match "[Summary of example.test]", res
  end

  test "#schemes" do
    res = capture { Runner.start(["schemes"]) }
    assert_match "CRAM-MD5", res
    assert_match "CLEARTEXT", res
  end

  test "#add_domain adds a new Domain" do
    assert_difference("Domain.count") do
      res = capture { Runner.start(%w[add_domain new-domain.test]) }
      assert_match '"new-domain.test" was successfully registered as a domain', res
    end
    assert Domain.exists?("new-domain.test")
  end

  test "#delete_domain deletes a Domain" do
    assert Domain.exists?("example.test")
    assert_difference("Domain.count", -1) do
      res = capture { Runner.start(%w[delete_domain example.test]) }
      assert_match '"example.test" was successfully deleted', res
    end
    assert_not Domain.exists?("example.test")
  end

  test "#add_admin adds an Admin" do
    assert_difference("Admin.count") do
      res = capture { Runner.start(%w[add_admin admin@new-domain.test password]) }
      assert_match '"admin@new-domain.test" was successfully registered as an admin', res
    end
    assert Admin.exists?("admin@new-domain.test")
    admin = Admin.find("admin@new-domain.test")
    expected = "{CRAM-MD5}9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740"
    assert_equal expected, admin.password
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

  test "#setup adds a Domain and its Admin" do
    assert_difference(%w[Domain.count Admin.count DomainAdmin.count]) do
      res = capture { Runner.start(%w[setup new-domain.test password]) }
      assert_match '"new-domain.test" was successfully registered as a domain', res
      assert_match '"admin@new-domain.test" was successfully registered as an admin', res
      assert_match '"new-domain.test" was successfully registered as a domain of admin@new-domain.test', res
    end
    assert Domain.exists?("new-domain.test")
    assert Admin.exists?("admin@new-domain.test")
    admin = Admin.find("admin@new-domain.test")
    assert admin.rel_domains.exists?("new-domain.test")
  end

  test "#log" do
    assert_nothing_raised do
      silent { Runner.start(["log"]) }
    end
  end

  test "#dump" do
    assert_nothing_raised do
      res = capture { Runner.start(["dump"]) }
      assert_match "Domains", res
      assert_match "example.test", res
      assert_match "admin@example.test", res
    end
  end
end
