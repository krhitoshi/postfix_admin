$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "..", "lib"))

require "minitest/autorun"
require "active_support"
require "postfix_admin"

class BaseTest < ActiveSupport::TestCase
  setup do
    config = { "database" => "mysql2://postfix:password@localhost/postfix" }
    @base = PostfixAdmin::Base.new(config)
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
    assert_equal expect, PostfixAdmin::Base::DEFAULT_CONFIG
  end

  test "#address_split" do
    assert_equal %w[user example.com], @base.address_split('user@example.com')
  end

  test "#new without config" do
    assert_raise(ArgumentError) { PostfixAdmin::Base.new }
  end
end
