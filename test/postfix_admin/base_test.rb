require "test_helper"

class BaseTest < ActiveSupport::TestCase
  setup do
    db_reset
    config = { "database" => "mysql2://postfix:password@localhost/postfix" }
    @base = Base.new(config)
  end

  test "DEFAULT_CONFIG" do
    expect = {
      "database" => "mysql2://postfix:password@localhost/postfix",
      "aliases" => 30,
      "mailboxes" => 30,
      "maxquota" => 100,
      "scheme" => "CRAM-MD5",
      "passwordhash_prefix" => true
    }
    assert_equal expect, Base::DEFAULT_CONFIG
  end

  test "#address_split" do
    assert_equal %w[user example.com], @base.address_split("user@example.com")
  end

  test "#new without config" do
    assert_raise(ArgumentError) { Base.new }
  end

  test "Default configurations to be correct" do
    assert_equal 30, @base.config[:aliases]
    assert_equal 30, @base.config[:mailboxes]
    assert_equal 100, @base.config[:maxquota]
    assert_equal "CRAM-MD5", @base.config[:scheme]
  end

  test "config database" do
    assert_equal "mysql2://postfix:password@localhost/postfix", @base.config[:database]
  end

  test "#add_domain can add a new domain" do
    assert_difference("Domain.count") do
      @base.add_domain("new-domain.test")
      assert Domain.exists?("new-domain.test")
    end
  end

  test "#add_domain raises an error for an existing domain" do
    create(:domain, domain: "example.com")
    assert Domain.exists?("example.com")
    assert_difference("Domain.count", 0) do
      assert_raise(PostfixAdmin::Error) { @base.add_domain("example.com") }
    end
  end

  test "#add_domain raises an error for an invalid domain" do
    assert_difference("Domain.count", 0) do
      assert_raise(PostfixAdmin::Error) { @base.add_domain("invalid_domain") }
    end
  end
end
