require "test_helper"

class BaseTest < ActiveSupport::TestCase
  setup do
    db_reset
    @domain = create(:domain, domain: "example.test")
    @domain.admins << build(:admin, username: "admin@example.test")
    @domain.rel_aliases   << build(:alias, address: "alias@example.test")
    @domain.rel_aliases   << build(:alias, address: "user@example.test")
    @domain.rel_mailboxes << build(:mailbox, local_part: "user")
    @domain.save!

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
    assert Domain.exists?("example.test")
    assert_difference("Domain.count", 0) do
      error = assert_raise(PostfixAdmin::Error) { @base.add_domain("example.test") }
      assert_match "Domain has already been registered: example.test", error.to_s
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
    assert_account_difference do
      @base.add_account("new_account@example.test", encrypted_password)
    end
    assert Mailbox.exists?("new_account@example.test")
    assert Alias.exists?("new_account@example.test")

    domain = Domain.find("example.test")
    assert domain.rel_mailboxes.exists?("new_account@example.test")

    mailbox = Mailbox.find("new_account@example.test")
    assert_equal "", mailbox.name
    assert_equal "new_account@example.test", mailbox.username
    assert_equal "new_account", mailbox.local_part
    assert_equal "example.test/new_account@example.test/", mailbox.maildir
    assert_equal encrypted_password, mailbox.password
    assert_equal 102_400_000, mailbox.quota

    # with name
    assert_account_difference do
      @base.add_account("john_smith@example.test", encrypted_password,
                        name: "John Smith")
    end

    mailbox_with_name = Mailbox.find("john_smith@example.test")
    assert_equal "John Smith", mailbox_with_name.name
  end

  test "#add_account raises an error for an empty password" do
    ["", nil].each do |empty_pass|
      assert_account_difference(0) do
        error = assert_raise(PostfixAdmin::Error) do
          @base.add_account("new_account@example.test", empty_pass)
        end
        assert_match "Empty password", error.to_s
      end
    end
  end

  test "#add_account raises an error for an invalid address" do
    assert_account_difference(0) do
      error = assert_raise(PostfixAdmin::Error) do
        @base.add_account("invalid.example.test", "password")
      end
      assert_match "Invalid email address", error.to_s
    end
  end

  test "#add_account raises an error for a non-existent domain name" do
    assert_account_difference(0) do
      error = assert_raise(PostfixAdmin::Error) do
        @base.add_account("user@unknown.example.test", "password")
      end
      assert_match "Could not find domain: unknown.example.test", error.to_s
    end
  end

  test "#add_account raises an error for an existing mailbox or an alias" do
    assert_account_difference(0) do
      error = assert_raise(PostfixAdmin::Error) do
        @base.add_account("user@example.test", "password")
      end
      assert_match "Alias has already been registered: user@example.test", error.to_s
    end

    assert_account_difference(0) do
      error = assert_raise(PostfixAdmin::Error) do
        @base.add_account("alias@example.test", "password")
      end
      assert_match "Alias has already been registered: alias@example.test", error.to_s
    end
  end

  test "#delete_domain deletes a domain" do
    assert Domain.exists?("example.test")
    assert Admin.exists?("admin@example.test")
    assert DomainAdmin.exists?(username: "admin@example.test",
                               domain: "example.test")
    assert Alias.exists?(domain: "example.test")
    assert Mailbox.exists?(domain: "example.test")

    assert_difference("Domain.count", -1) do
      assert_nothing_raised do
        @base.delete_domain("example.test")
      end
    end

    assert_not Domain.exists?("example.test")
    assert_not Admin.exists?("admin@example.test")
    assert_not DomainAdmin.exists?(username: "admin@example.test",
                                   domain: "example.test")
    assert_not Alias.exists?(domain: "example.test")
    assert_not Mailbox.exists?(domain: "example.test")
  end

  test "#delete_domain raises an error for a non-existent domain name" do
    error = assert_raise(PostfixAdmin::Error) do
      @base.delete_domain("non-existent.test")
    end
    assert_match "Could not find domain: non-existent.test", error.to_s
  end

  test "#delete_account deletes an account" do
    assert Alias.exists?("user@example.test")
    assert Mailbox.exists?("user@example.test")

    assert_account_difference(-1) do
      assert_nothing_raised do
        @base.delete_account("user@example.test")
      end
    end

    assert_not Alias.exists?("user@example.test")
    assert_not Mailbox.exists?("user@example.test")
  end

  test "#delete_account raises an error for a non-existent account" do
    error = assert_raise(PostfixAdmin::Error) do
      @base.delete_account("unknown@example.test")
    end
    assert_match "Could not find account: unknown@example.test", error.to_s
  end
end
