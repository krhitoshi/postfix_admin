require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/base'

RSpec.describe PostfixAdmin::Base do
  before do
    @base = Base.new({'database' => 'mysql2://postfix:password@localhost/postfix'})
  end

  it "DEFAULT_CONFIG" do
    expected = {
      "database" => "mysql2://postfix:password@localhost/postfix",
      "aliases" => 30,
      "mailboxes" => 30,
      "maxquota" => 100,
      "scheme" => "CRAM-MD5",
      "passwordhash_prefix" => true
    }
    expect(Base::DEFAULT_CONFIG).to eq(expected)
  end

  describe "#config" do
    it "Default configurations to be correct" do
      expect(@base.config[:aliases]).to eq(30)
      expect(@base.config[:mailboxes]).to eq(30)
      expect(@base.config[:maxquota]).to eq(100)
      expect(@base.config[:scheme]).to eq("CRAM-MD5")
      expect(@base.config[:passwordhash_prefix]).to be(true)
    end

    it "#config[:passwordhash_prefix]" do
      expect(Base.new({}).config[:passwordhash_prefix]).to be(true)
      expect(Base.new({"passwordhash_prefix" => true})
                 .config[:passwordhash_prefix]).to be(true)
      expect(Base.new({"passwordhash_prefix" => false})
                 .config[:passwordhash_prefix]).to be(false)
    end

    it "#config[:database]" do
      expect(@base.config[:database]).to eq("mysql2://postfix:password@localhost/postfix")
    end
  end

  describe "#add_domain" do
    it "can adds a new domain" do
      expect {
        @base.add_domain("new-domain.test")
      }.to change { Domain.count }.by(1)
      expect(Domain.exists?("new-domain.test")).to be(true)
    end

    it "raises an error for an existing domain" do
      expect(Domain.exists?("example.com")).to be(true)
      expect {
        @base.add_domain("example.com")
      }.to raise_error(PostfixAdmin::Error,
                       "Domain has already been registered: example.com")
      expect(Domain.count).to eq(Domain.count)
    end

    it "raises an error for an invalid domain" do
      expect {
        @base.add_domain("invalid_domain")
      }.to raise_error(PostfixAdmin::Error, "Invalid domain name: invalid_domain")
      expect(Domain.count).to eq(Domain.count)
    end
  end

  describe "#delete_domain" do
    it "deletes a domain" do
      expect(Domain.exists?("example.com")).to be(true)
      expect(Admin.exists?("admin@example.com")).to be(true)
      expect(DomainAdmin.exists?(username: "admin@example.com", domain: "example.com")).to be(true)
      expect(Alias.exists?(domain: "example.com")).to be(true)
      expect(Mailbox.exists?(domain: "example.com")).to be(true)

      expect {
        @base.delete_domain("example.com")
      }.to change { Domain.count }.by(-1)

      expect(Domain.exists?("example.com")).to be(false)
      # `delete_domain` does not delete a admin user anymore
      expect(Admin.exists?("admin@example.com")).to be(true)
      expect(DomainAdmin.exists?(username: "admin@example.com", domain: "example.com")).to be(false)
      expect(Alias.exists?(domain: "example.com")).to be(false)
      expect(Mailbox.exists?(domain: "example.com")).to be(false)
    end

    it "raises an error for a non-existent domain name" do
      expect {
        @base.delete_domain("non-existent.test")
      }.to raise_error(PostfixAdmin::Error, "Could not find domain: non-existent.test")
    end
  end

  describe "#add_admin" do
    it "can add an new admin" do
      num_admins = Admin.count
      @base.add_admin('admin@example.net', 'password')
      expect(Admin.exists?('admin@example.net')).to be(true)
      expect(Admin.count - num_admins).to eq 1
    end

    it "refuse empty password" do
      expect { @base.add_admin('admin@example.net', '') }.to raise_error Error
    end

    it "refuse nil password" do
      expect { @base.add_admin('admin@example.net', nil) }.to raise_error Error
    end

    it "can not add exist admin" do
      expect { @base.add_admin('admin@example.com', 'password') }.to raise_error Error
    end
  end

  describe "#add_admin_domain" do
    it "#add_admin_domain" do
      @base.add_admin_domain('admin@example.com', 'example.org')
      d = Domain.find('example.org')
      expect(Admin.find('admin@example.com').has_domain?(d)).to be(true)
    end

    it "can not add unknown domain for an admin" do
      expect { @base.add_admin_domain('admin@example.com', 'unknown.example.com') }.to raise_error Error
    end

    it "can not add domain for unknown admin" do
      expect { @base.add_admin_domain('unknown_admin@example.com', 'example.net') }.to raise_error Error
    end

    it "can not add a domain which the admin has already privileges for" do
      expect { @base.add_admin_domain('admin@example.com', 'example.com') }.to raise_error Error
    end
  end

  describe "#delete_admin_domain" do
    it "#delete_admin_domain" do
      d = Domain.find('example.org')
      expect { @base.delete_admin_domain('admin@example.com', 'example.com') }.to_not raise_error
      expect(Admin.find('admin@example.com').has_domain?(d)).to be(false)
    end

    it "can not delete not administrated domain" do
      expect { @base.delete_admin_domain('admin@example.com', 'example.org') }.to raise_error Error
    end

    it "raise error when unknown admin" do
      expect { @base.delete_admin_domain('unknown_admin@example.com', 'example.com') }.to raise_error Error
    end

    it "raise error when unknown domain" do
      expect { @base.delete_admin_domain('admin@example.com', 'unknown.example.com') }.to raise_error Error
    end
  end

  describe "#add_account" do
    it "adds a Mailbox and an Alias" do
      expect {
        @base.add_account("new_account@example.com", CRAM_MD5_PASS)
      }.to change{ Mailbox.count }.by(1).and change{ Alias.count }.by(1)
      expect(Mailbox.exists?("new_account@example.com")).to be(true)
      expect(Alias.exists?("new_account@example.com")).to be(true)

      domain = Domain.find("example.com")
      expect(domain.rel_mailboxes.exists?("new_account@example.com")).to be(true)

      mailbox = Mailbox.find("new_account@example.com")
      expect(mailbox.name).to eq("")
      expect(mailbox.username).to eq("new_account@example.com")
      expect(mailbox.local_part).to eq("new_account")
      expect(mailbox.maildir).to eq("example.com/new_account@example.com/")
      expect(mailbox.password).to eq(CRAM_MD5_PASS)
      expect(mailbox.quota).to eq(102_400_000)
    end

    context "with name" do
      it "adds a Mailbox and an Alias with name" do
        expect {
          @base.add_account("john_smith@example.com", CRAM_MD5_PASS, name: "John Smith")
        }.to change{ Mailbox.count }.by(1).and change{ Alias.count }.by(1)
        mailbox_with_name = Mailbox.find("john_smith@example.com")
        expect(mailbox_with_name.name).to eq("John Smith")
      end
    end

    it "raises an error for an empty password" do
      ["", nil].each do |empty_pass|
        expect {
          @base.add_account("new_account@example.com", empty_pass)
        }.to raise_error(PostfixAdmin::Error, "Empty password")
        expect(Mailbox.count).to eq(Mailbox.count)
        expect(Alias.count).to eq(Alias.count)
      end
    end

    it "raises an error for an invalid address" do
      expect {
        @base.add_account("invalid.example.com", "password")
      }.to raise_error(PostfixAdmin::Error, "Invalid email address: invalid.example.com")
      expect(Mailbox.count).to eq(Mailbox.count)
      expect(Alias.count).to eq(Alias.count)
    end

    it "raises an error for a non-existent domain name" do
      expect {
        @base.add_account("user@unknown.example.com", "password")
      }.to raise_error(PostfixAdmin::Error, "Could not find domain: unknown.example.com")
      expect(Mailbox.count).to eq(Mailbox.count)
      expect(Alias.count).to eq(Alias.count)
    end

    it "raises an error for an existing mailbox or an alias" do
      expect {
        @base.add_account("user@example.com", "password")
      }.to raise_error(PostfixAdmin::Error, "Alias has already been registered: user@example.com")
      expect(Mailbox.count).to eq(Mailbox.count)
      expect(Alias.count).to eq(Alias.count)

      expect {
        @base.add_account("alias@example.com", "password")
      }.to raise_error(PostfixAdmin::Error, "Alias has already been registered: alias@example.com")
      expect(Mailbox.count).to eq(Mailbox.count)
      expect(Alias.count).to eq(Alias.count)
    end
  end

  describe "#delete_account" do
    it "deletes a Mailbox and an Alias" do
      expect(Alias.exists?("user@example.com")).to be(true)
      expect(Mailbox.exists?("user@example.com")).to be(true)

      expect {
        @base.delete_account("user@example.com")
      }.to change{ Mailbox.count }.by(-1).and change{ Alias.count }.by(-1)

      expect(Alias.exists?("user@example.com")).to be(false)
      expect(Mailbox.exists?("user@example.com")).to be(false)
    end

    it "raises an error for a non-existent account" do
      expect {
        @base.delete_account("unknown@example.com")
      }.to raise_error(PostfixAdmin::Error, "Could not find account: unknown@example.com")
    end
  end

  describe "#add_alias" do
    it "can add a new alias" do
      num_aliases = Alias.count
      expect { @base.add_alias('new_alias@example.com', 'goto@example.jp') }.to_not raise_error
      expect(Alias.count - num_aliases).to eq 1
      expect(Alias.exists?('new_alias@example.com')).to be(true)
    end

    it "can not add an alias which has a same name as a mailbox" do
      expect { @base.add_alias('user@example.com', 'goto@example.jp') }.to raise_error Error
    end

    it "can not add an alias which has a sama name as other alias" do
      @base.add_alias('new_alias@example.com', 'goto@example.jp')
      expect { @base.add_alias('new_alias@example.com', 'goto@example.jp') }.to raise_error Error
    end

    it "can not add an alias of unknown domain" do
      expect { @base.add_alias('new_alias@unknown.example.com', 'goto@example.jp') }.to raise_error Error
    end
  end

  describe "#delete_alias" do
    it "can delete an alias" do
      expect { @base.delete_alias('alias@example.com') }.to_not raise_error
      expect(Alias.exists?('alias@example.com')).to be(false)
    end

    it "can not delete mailbox" do
      expect { @base.delete_alias('user@example.com') }.to raise_error Error
    end

    it "can not delete unknown alias" do
      expect { @base.delete_alias('unknown@example.com') }.to raise_error Error
    end
  end

  describe "#delete_admin" do
    it "can delete an admin" do
      expect { @base.delete_admin('admin@example.com') }.to_not raise_error
      expect(Admin.exists?('admin@example.com')).to be(false)
    end

    it "can not delete unknown admin" do
      expect { @base.delete_admin('unknown_admin@example.com') }.to raise_error Error
    end
  end
end
