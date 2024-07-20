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
      domain = Domain.find("new-domain.test")
      expect(domain.transport).to eq("virtual")
      expect(domain.description).to eq("")
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
    before do
      @user = "new-user@example.com"
      @domain_name = "example.com"
      @domain = Domain.find(@domain_name)
    end

    it "adds an account (a Mailbox and an Alias)" do
      expect(Mailbox.exists?(@user)).to be(false)
      expect(Alias.exists?(@user)).to be(false)

      expect {
        @base.add_account(@user, CRAM_MD5_PASS)
      }.to change{ Mailbox.count }.by(1).and change{ Alias.count }.by(1)

      expect(Mailbox.exists?(@user)).to be(true)
      expect(Alias.exists?(@user)).to be(true)

      expect(@domain.rel_mailboxes.exists?(@user)).to be(true)

      mailbox = Mailbox.find(@user)
      expect(mailbox.username).to eq(@user)
      expect(mailbox.password).to eq(CRAM_MD5_PASS)
      expect(mailbox.maildir).to eq("example.com/new-user@example.com/")
      expect(mailbox.local_part).to eq("new-user")
      expect(mailbox.name).to eq("")
      expect(mailbox.domain).to eq("example.com")
      expect(mailbox.quota).to eq(102_400_000)
      expect(mailbox.active).to be(true)

      new_alias = Alias.find(@user)
      expect(new_alias.address).to eq(@user)
      expect(new_alias.goto).to eq(@user)
      expect(new_alias.domain).to eq("example.com")
      expect(new_alias.active).to be(true)
    end

    context "when domain has unlimited status for mailboxes" do
      it "can add an account" do
        @domain.update!(mailboxes: Domain::UNLIMITED)
        expect(Mailbox.exists?(@user)).to be(false)
        expect(Alias.exists?(@user)).to be(false)

        expect {
          @base.add_account(@user, CRAM_MD5_PASS)
        }.to change{ Mailbox.count }.by(1).and change{ Alias.count }.by(1)

        expect(Mailbox.exists?(@user)).to be(true)
        expect(Alias.exists?(@user)).to be(true)

        expect(@domain.rel_mailboxes.exists?(@user)).to be(true)
      end
    end

    context "when domain has disabled status for mailboxes" do
      it "can not add an account" do
        @domain.update!(mailboxes: Domain::DISABLED)
        expect { @base.add_account(@user, CRAM_MD5_PASS) }.to \
          raise_error(PostfixAdmin::Error,
                      "Failed to save PostfixAdmin::Mailbox: Domain has a disabled status for mailboxes")
      end
    end

    context "when number of mailboxes has already reached maximum" do
      it "can not add an account" do
        count = @domain.mailbox_count
        @domain.update!(mailboxes: count)
        expect { @base.add_account(@user, CRAM_MD5_PASS) }.to \
          raise_error(PostfixAdmin::Error,
                      "Failed to save PostfixAdmin::Mailbox: Domain has already reached the maximum number of mailboxes (maximum: #{count})")
      end
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
          @base.add_account("new-user@example.com", empty_pass)
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
    before do
      @alias = "new-alias@example.com"
      @domain = Domain.find("example.com")
      @goto = "goto@example.jp"
    end

    it "can add an alias" do
      expect(Alias.exists?(@alias)).to be(false)
      expect {
        @base.add_alias(@alias, @goto)
      }.to change{ Alias.count }.by(1)
      expect(Alias.exists?(@alias)).to be(true)
    end

    context "when domain has unlimited status for aliases" do
      it "can add an alias" do
        @domain.update!(aliases: Domain::UNLIMITED)
        expect(Alias.exists?(@alias)).to be(false)
        expect {
          @base.add_alias(@alias, @goto)
        }.to change{ Alias.count }.by(1)
        expect(Alias.exists?(@alias)).to be(true)
      end
    end

    context "when domain has disabled status for aliases" do
      it "can not add an alias" do
        @domain.update!(aliases: Domain::DISABLED)
        expect { @base.add_alias(@alias, @goto) }.to \
          raise_error(PostfixAdmin::Error,
                      "Failed to save PostfixAdmin::Alias: Domain has a disabled status for aliases")
      end
    end

    context "when number of aliases has already reached maximum" do
      it "can not add an alias" do
        count = @domain.pure_alias_count
        @domain.update!(aliases: count)
        expect { @base.add_alias(@alias, @goto) }.to \
          raise_error(PostfixAdmin::Error,
                      "Failed to save PostfixAdmin::Alias: Domain has already reached the maximum number of aliases (maximum: #{count})")
      end
    end

    it "can not add an alias which has a same name as a mailbox" do
      expect { @base.add_alias('user@example.com', @goto) }.to raise_error Error
    end

    it "can not add an alias which has a sama name as other alias" do
      @base.add_alias('new_alias@example.com', 'goto@example.jp')
      expect { @base.add_alias('new_alias@example.com', @goto) }.to raise_error Error
    end

    it "can not add an alias of unknown domain" do
      expect { @base.add_alias('new_alias@unknown.example.com', @goto) }.to raise_error Error
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
