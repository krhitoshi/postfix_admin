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
      error = assert_raise(PostfixAdmin::Error) { @base.add_domain("example.com") }
      assert_match "Domain has already been registered: example.com", error.to_s
    end
  end

  test "#add_domain raises an error for an invalid domain" do
    assert_difference("Domain.count", 0) do
      error = assert_raise(PostfixAdmin::Error) { @base.add_domain("invalid_domain") }
      assert_match "Invalid domain name", error.to_s
    end
  end

  test "#add_account adds a new account" do
    encrypted_password = "{CRAM-MD5}9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740"
    create(:domain, domain: "example.com")
    assert_account_difference do
      @base.add_account("new_account@example.com", encrypted_password)
    end
    assert Mailbox.exists?("new_account@example.com")
    assert Alias.exists?("new_account@example.com")

    domain = Domain.find("example.com")
    assert domain.rel_mailboxes.exists?("new_account@example.com")

    mailbox = Mailbox.find("new_account@example.com")
    assert_equal "", mailbox.name
    assert_equal "new_account@example.com", mailbox.username
    assert_equal "new_account", mailbox.local_part
    assert_equal "example.com/new_account@example.com/", mailbox.maildir
    assert_equal encrypted_password, mailbox.password
    assert_equal 102_400_000, mailbox.quota

    assert_account_difference do
      @base.add_account("new_account2@example.com", encrypted_password,
                        "New Account #2")
    end

    mailbox2 = Mailbox.find("new_account2@example.com")
    assert_equal "New Account #2", mailbox2.name
  end

  test "#add_account raises an error for an empty password" do
    ["", nil].each do |empty_pass|
      assert_account_difference(0) do
        error = assert_raise(PostfixAdmin::Error) do
          @base.add_account("new_account@example.com", empty_pass)
        end
        assert_match "Empty password", error.to_s
      end
    end
  end

  test "#add_account raises an error for an invalid address" do
    assert_account_difference(0) do
      error = assert_raise(PostfixAdmin::Error) do
        @base.add_account("invalid.example.com", "password")
      end
      assert_match "Invalid email address", error.to_s
    end
  end

  test "#add_account raises an error for an unknown domain name" do
    assert_account_difference(0) do
      error = assert_raise(PostfixAdmin::Error) do
        @base.add_account("user@unknown.example.com", "password")
      end
      assert_match "Could not find domain: unknown.example.com", error.to_s
    end
  end

  test "#add_account raises an error for an existing mailbox or an alias" do
    domain = create(:domain, domain: "example.com")
    domain.rel_aliases   << build(:alias, address: "alias@example.com")
    domain.rel_aliases   << build(:alias, address: "user@example.com")
    domain.rel_mailboxes << build(:mailbox, local_part: "user")
    domain.save!
    assert_account_difference(0) do
      error = assert_raise(PostfixAdmin::Error) do
        @base.add_account("user@example.com", "password")
      end
      assert_match "Alias has already been registered: user@example.com", error.to_s
    end

    assert_account_difference(0) do
      error = assert_raise(PostfixAdmin::Error) do
        @base.add_account("alias@example.com", "password")
      end
      assert_match "Alias has already been registered: alias@example.com", error.to_s
    end
  end

  test "#delete_domain deletes a domain" do
    domain = create(:domain, domain: "example.com")
    domain.admins << build(:admin, username: "admin@example.com")
    domain.rel_aliases   << build(:alias, address: "alias@example.com")
    domain.rel_aliases   << build(:alias, address: "user@example.com")
    domain.rel_mailboxes << build(:mailbox, local_part: "user")
    domain.save!

    assert Domain.exists?("example.com")
    assert Admin.exists?("admin@example.com")
    assert DomainAdmin.exists?(username: "admin@example.com",
                               domain: "example.com")
    assert Alias.exists?(domain: "example.com")
    assert Mailbox.exists?(domain: "example.com")

    assert_difference("Domain.count", -1) do
      assert_nothing_raised do
        @base.delete_domain("example.com")
      end
    end

    assert_not Domain.exists?("example.com")
    assert_not Admin.exists?("admin@example.com")
    assert_not DomainAdmin.exists?(username: "admin@example.com",
                                   domain: "example.com")
    assert_not Alias.exists?(domain: "example.com")
    assert_not Mailbox.exists?(domain: "example.com")
  end

  test "#delete_domain raises an error for an unknown domain name" do
    error = assert_raise(PostfixAdmin::Error) { @base.delete_domain("example.com") }
    assert_match "Could not find domain: example.com", error.to_s
  end
end
