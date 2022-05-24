require "test_helper"
require "postfix_admin/runner"

class RunnerTest < ActiveSupport::TestCase
  setup do
    db_reset
    @domain = create(:domain, domain: "example.test")
  end

  test "#add_domain adds a new domain" do
    assert_difference("Domain.count") do
      res = capture(:stdout) { Runner.start(%w[add_domain new-domain.test]) }
      assert_match '"new-domain.test" was successfully registered as a domain', res
    end
    assert Domain.exists?("new-domain.test")
  end

  test "#delete_domain deletes a domain" do
    assert Domain.exists?("example.test")
    assert_difference("Domain.count", -1) do
      res = capture(:stdout) { Runner.start(%w[delete_domain example.test]) }
      assert_match '"example.test" was successfully deleted', res
    end
    assert_not Domain.exists?("example.test")
  end

  test "#add_admin adds an Admin" do
    assert_difference("Admin.count") do
      res = capture(:stdout) { Runner.start(%w[add_admin admin@new-domain.test password]) }
      assert_match '"admin@new-domain.test" was successfully registered as an admin', res
    end
  end
end
