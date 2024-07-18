require File.join(__dir__, "..", "spec_helper")
require "postfix_admin/models/mailbox"

RSpec.describe PostfixAdmin::Mailbox do
  before do
    @mailbox = Mailbox.find('user@example.com')
    @domain = Domain.find("example.com")
  end

  it "active" do
    expect(@mailbox.active).to be(true)
    @domain.rel_mailboxes << build(:mailbox, local_part: "non_active_user",
                                            active: false)
    @domain.save!

    mailbox = Mailbox.find('non_active_user@example.com')
    expect(mailbox.active).to be(false)
    expect(mailbox.maildir).to eq "example.com/non_active_user@example.com/"
  end

  it "#quota_unlimited?" do
    @domain.update!(maxquota: Domain::UNLIMITED_MAXQUOTA)
    @mailbox.update!(quota: 1000 * PostfixAdmin::KB_TO_MB)
    expect(@mailbox.quota_unlimited?).to be(false)

    @mailbox.update!(quota: Mailbox::UNLIMITED_QUOTA)
    expect(@mailbox.reload.quota_unlimited?).to be(true)
  end

  it "can use long maildir" do
    @domain.rel_mailboxes << build(:mailbox, local_part: "long_maildir_user",
                                  maildir: "looooooooooooong_path/example.com/long_maildir_user@example.com/")
    expect(@domain.save).to be(true)
    expect(Mailbox.find("long_maildir_user@example.com").maildir).to eq "looooooooooooong_path/example.com/long_maildir_user@example.com/"
  end

  describe ".exists?" do
    it "returns true for exist account (mailbox)" do
      expect(Mailbox.exists?('user@example.com')).to be(true)
    end

    it "returns false for alias" do
      expect(Mailbox.exists?('alias@example.com')).to be(false)
    end

    it "returns false for unknown account (mailbox)" do
      expect(Mailbox.exists?('unknown@unknown.example.com')).to be(false)
    end
  end

  it "scheme_prefix" do
    expect(@mailbox.scheme_prefix).to eq "{CRAM-MD5}"

    @mailbox.update(password: BLF_CRYPT_PASS)
    expect(@mailbox.scheme_prefix).to eq "{BLF-CRYPT}"

    @mailbox.update(password: CRAM_MD5_PASS_WITHOUT_PREFIX)
    expect(@mailbox.scheme_prefix).to be nil
  end

  describe "#quota_mb" do
    it "returns quota in MB" do
      expect(@mailbox.quota_mb).to eq 100
      @mailbox.quota = 2048_000_000
      expect(@mailbox.quota_mb).to eq 2000
    end
  end

  context "set quota" do
    context "when domain has maxquota (not unlimited)" do
      before do
        @maxquota_mb = 1000
        @mailbox.rel_domain.update!(maxquota: @maxquota_mb)
      end

      it "can set quota to domain's maxquota" do
        new_quota = @maxquota_mb * PostfixAdmin::KB_TO_MB
        expect(@mailbox.quota).not_to eq(new_quota)
        expect { @mailbox.update!(quota: new_quota) }.not_to raise_error
        expect(@mailbox.quota).to eq(new_quota)
      end

      it "can set quota to value which is less than domain's maxquota" do
        new_quota_mb = @maxquota_mb - 100
        new_quota = new_quota_mb * PostfixAdmin::KB_TO_MB
        expect { @mailbox.update!(quota: new_quota) }.not_to raise_error
        expect(@mailbox.quota).to eq(new_quota)
      end

      it "cannot set quota to value greater than domain's maxquota" do
        new_quota_mb = @maxquota_mb + 100
        new_quota = new_quota_mb * PostfixAdmin::KB_TO_MB
        expect { @mailbox.update!(quota: new_quota) }.to \
          raise_error(ActiveRecord::RecordInvalid,
                      "Validation failed: Quota must be less than or equal to 1000 MB")
      end

      it "cannot set quota to 0 (unlimited)" do
        expect { @mailbox.update!(quota: 0) }.to \
          raise_error(ActiveRecord::RecordInvalid,
                      "Validation failed: Quota cannot be set to 0 (unlimited), " \
                        "Quota must be less than or equal to 1000 MB")
      end
    end

    context "when domain has unlimited maxquota" do
      before do
        @mailbox.rel_domain.update!(maxquota: Domain::UNLIMITED_MAXQUOTA)
      end

      it "can set quota to any value such as 1 TB" do
        new_quota_mb = 1000_000 # 1 TB
        new_quota = new_quota_mb * PostfixAdmin::KB_TO_MB
        expect { @mailbox.update!(quota: new_quota) }.not_to raise_error
        expect(@mailbox.quota).to eq(new_quota)
      end

      it "can set quota to 0 (unlimited)" do
        expect { @mailbox.update!(quota: 0) }.not_to raise_error
        expect(@mailbox.quota).to eq(0)
      end
    end
  end

  describe "#quota_mb=" do
    it "set quota in MB" do
      @mailbox.quota_mb = 2000
      expect(@mailbox.quota_mb).to eq 2000
      expect(@mailbox.quota).to eq 2048_000_000
    end
  end

  describe "#quota_mb_str" do
    it "returns quota string in MB" do
      expect(@mailbox.quota_mb_str).to eq " 100.0"
      expect(@mailbox.quota_mb_str(format: "%.1f")).to eq "100.0"
    end

    context "when quota is 0 (Unlimited)" do
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
