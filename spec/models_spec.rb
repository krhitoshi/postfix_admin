require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'active_record'
require 'postfix_admin/models/application_record'
require 'postfix_admin/models/admin'
require 'postfix_admin/models/domain'
require 'postfix_admin/models/mailbox'
require 'postfix_admin/models/alias'
require 'postfix_admin/models/domain_admin'
require 'postfix_admin/models/log'
require 'postfix_admin/models/quota2'

RSpec.describe PostfixAdmin::Admin do
  before do
    @admin = Admin.find('admin@example.com')
  end

  it ".exists?" do
    expect(Admin.exists?('admin@example.com')).to be true
    expect(Admin.exists?('all@example.com')).to be true
    expect(Admin.exists?('unknown@example.com')).to be false
  end

  it "active" do
    expect(Admin.find('admin@example.com').active).to be true
    expect(Admin.find('all@example.com').active).to be true
    create(:admin, username: "non_active_admin@example.com", active: false)

    expect(Admin.find('non_active_admin@example.com').active).to be false
  end

  it "#super_admin?" do
    expect(Admin.find('admin@example.com').super_admin?).to be false
    expect(Admin.find('all@example.com').super_admin?).to be true
  end

  describe "#super_admin=" do
    it "disable super admin flag" do
      expect { Admin.find('all@example.com').super_admin = false }.to_not raise_error
      admin = Admin.find('all@example.com')
      expect(admin.super_admin?).to be false
      expect(admin.superadmin).to be false if admin.has_superadmin_column?
    end

    it "should not delete 'ALL' domain" do
      Admin.find('all@example.com').super_admin = false
      expect(Domain.exists?('ALL')).to be true
    end

    it "enable super admin flag" do
      expect { Admin.find('admin@example.com').super_admin = true }.to_not raise_error
      admin = Admin.find('all@example.com')
      expect(admin.super_admin?).to be true
      expect(admin.superadmin).to be true if admin.has_superadmin_column?
    end
  end

  describe "#has_domain?" do
    it "returns true when the admin has privileges for the domain" do
      d = Domain.find('example.com')
      expect(Admin.find('admin@example.com').has_domain?(d)).to be true
    end

    it "returns false when the admin does not have privileges for the domain" do
      d = Domain.find('example.org')
      expect(Admin.find('admin@example.com').has_domain?(d)).to be false
    end

    it "returns true when super admin and exist domain" do
      d = Domain.find('example.com')
      expect(Admin.find('all@example.com').has_domain?(d)).to be true
    end

    it "returns true when super admin and another domain" do
      d = Domain.find('example.org')
      expect(Admin.find('all@example.com').has_domain?(d)).to be true
    end
  end

  it "scheme_prefix" do
    expect(@admin.scheme_prefix).to eq "{CRAM-MD5}"

    @admin.update(password: BLF_CRYPT_PASS)
    expect(@admin.scheme_prefix).to eq "{BLF-CRYPT}"

    @admin.update(password: CRAM_MD5_PASS_WITHOUT_PREFIX)
    expect(@admin.scheme_prefix).to be nil
  end
end

RSpec.describe PostfixAdmin::Domain do
  before do
    @base = PostfixAdmin::Base.new({'database' => 'sqlite::memory:'})
  end

  it ".exists?" do
    expect(Domain.exists?('example.com')).to be true
    expect(Domain.exists?('example.org')).to be true
    expect(Domain.exists?('unknown.example.com')).to be false
  end

  it "active" do
    expect(Domain.find('example.com').active).to be true
    expect(Domain.find('example.org').active).to be true

    create(:domain, domain: "non-active.example.com", active: false)
    expect(Domain.find('non-active.example.com').active).to be false
  end

  describe "#num_total_aliases and .num_total_aliases" do
    it "when only alias@example.com" do
      expect(Alias.pure.count).to eq 1
      expect(Domain.find('example.com').pure_aliases.count).to eq 1
    end

    it "should increase one if you add an alias" do
      @base.add_alias('new_alias@example.com', 'goto@example.jp')
      expect(Alias.pure.count).to eq 2
      expect(Domain.find('example.com').pure_aliases.count).to eq 2
    end

    it "should not increase if you add an account" do
      @base.add_account('user2@example.com', 'password')
      expect(Alias.pure.count).to eq 1
      expect(Domain.find('example.com').pure_aliases.count).to eq 1
    end

    it ".num_total_aliases should not increase if you add an account and an aliase for other domain" do
      @base.add_account('user@example.org', 'password')
      expect(Alias.pure.count).to eq 1
      expect(Domain.find('example.com').pure_aliases.count).to eq 1
      @base.add_alias('new_alias@example.org', 'goto@example.jp')
      expect(Alias.pure.count).to eq 2
      expect(Domain.find('example.com').pure_aliases.count).to eq 1
    end
  end
end

RSpec.describe PostfixAdmin::Mailbox do
  before do
    @mailbox = Mailbox.find('user@example.com')
  end

  it "active" do
    expect(@mailbox.active).to be true
    domain = Domain.find('example.com')
    domain.rel_mailboxes << build(:mailbox, local_part: "non_active_user",
                                            active: false)
    domain.save!

    mailbox = Mailbox.find('non_active_user@example.com')
    expect(mailbox.active).to be false
    expect(mailbox.maildir).to eq "example.com/non_active_user@example.com/"
  end

  it "can use long maildir" do
    domain = Domain.find('example.com')
    domain.rel_mailboxes << build(:mailbox, local_part: "long_maildir_user",
                                  maildir: "looooooooooooong_path/example.com/long_maildir_user@example.com/")
    expect(domain.save).to be true
    expect(Mailbox.find("long_maildir_user@example.com").maildir).to eq "looooooooooooong_path/example.com/long_maildir_user@example.com/"
  end

  describe ".exists?" do
    it "returns true for exist account (mailbox)" do
      expect(Mailbox.exists?('user@example.com')).to be true
    end

    it "returns false for alias" do
      expect(Mailbox.exists?('alias@example.com')).to be false
    end

    it "returns false for unknown account (mailbox)" do
      expect(Mailbox.exists?('unknown@unknown.example.com')).to be false
    end
  end

  it "scheme_prefix" do
    expect(@mailbox.scheme_prefix).to eq "{CRAM-MD5}"

    @mailbox.update(password: BLF_CRYPT_PASS)
    expect(@mailbox.scheme_prefix).to eq "{BLF-CRYPT}"

    @mailbox.update(password: CRAM_MD5_PASS_WITHOUT_PREFIX)
    expect(@mailbox.scheme_prefix).to be nil
  end

  describe "#quota_mb_str" do
    it "returns quota string in MB" do
      expect(@mailbox.quota_mb_str).to eq " 100.0"
      expect(@mailbox.quota_mb_str(format: "%.1f")).to eq "100.0"
    end

    context "when quota is  (Unlimited)" do
      it "returns 'Unlimited'" do
        @mailbox.update(quota: 0)
        expect(@mailbox.quota_mb_str).to eq "Unlimited"
      end
    end

    context "when quota is -1 (Disabled)" do
      it "returns 'Disabled'" do
        @mailbox.update(quota: -1)
        expect(@mailbox.quota_mb_str).to eq "Disabled"
      end
    end
  end

  describe "#quota_usage_str" do
    it "returns quota usage string in MB" do
      expect(@mailbox.quota_usage_str).to eq "  75.0"
      expect(@mailbox.quota_usage_str(format: "%.1f")).to eq "75.0"
    end
  end
end

RSpec.describe PostfixAdmin::Alias do
  it "active" do
    domain = Domain.find('example.com')
    domain.rel_aliases << build(:alias, address: "non_active_alias@example.com",
                                        active: false)
    domain.save

    expect(Alias.find('user@example.com').active).to be true
    expect(Alias.find('alias@example.com').active).to be true
    expect(Alias.find('non_active_alias@example.com').active).to  be false
  end

  describe ".exists?" do
    it "returns true when exist alias and account" do
      expect(Alias.exists?('user@example.com')).to be true
      expect(Alias.exists?('alias@example.com')).to be true
    end

    it "returns false when unknown alias" do
      expect(Alias.exists?('unknown@unknown.example.com')).to be false
    end
  end

  describe ".mailbox?" do
    it "when there is same address in maiboxes returns true" do
      expect(Alias.find('user@example.com').mailbox?).to be true
    end

    it "when there is no same address in maiboxes returns false" do
      expect(Alias.find('alias@example.com').mailbox?).to be false
    end
  end

  it "#pure" do
    expect(Alias.pure.exists?("alias@example.com")).to be(true)
    expect(Alias.pure.exists?("user@example.com")).to be(false)
  end

  it "forward" do
    expect(Alias.forward.exists?("alias@example.com")).to be(false)
    expect(Alias.forward.exists?("user@example.com")).to be(true)
  end
end
