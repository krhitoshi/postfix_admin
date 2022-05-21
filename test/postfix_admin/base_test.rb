$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "..", "lib"))

require "minitest/autorun"
require "active_support"
require "postfix_admin"

class BaseTest < ActiveSupport::TestCase
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
end
