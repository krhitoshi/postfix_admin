require "test_helper"
require "postfix_admin/runner"

class RunnerTest < ActiveSupport::TestCase
  setup do
    db_reset
  end

  test "#add_domain adds a new domain" do
    assert_difference("Domain.count") do
      res = capture(:stdout) { Runner.start(%w[add_domain new-domain.test]) }
      assert_match '"new-domain.test" was successfully registered as a domain', res
    end
    assert Domain.exists?("new-domain.test")
  end
end
