require "test_helper"

class BaseTest < ActiveSupport::TestCase
  include PostfixAdmin

  setup do
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
end
