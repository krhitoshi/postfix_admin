require File.join(__dir__, "..", "spec_helper")
require "postfix_admin/models/admin"

RSpec.describe PostfixAdmin::Admin do
  before do
    @admin = Admin.find('admin@example.com')
  end

  it ".exists?" do
    expect(Admin.exists?('admin@example.com')).to be(true)
    expect(Admin.exists?('all@example.com')).to be(true)
    expect(Admin.exists?('unknown@example.com')).to be(false)
  end

  it "active" do
    expect(Admin.find('admin@example.com').active).to be(true)
    expect(Admin.find('all@example.com').active).to be(true)
    create(:admin, username: "non_active_admin@example.com", active: false)

    expect(Admin.find('non_active_admin@example.com').active).to be(false)
  end

  it "#super_admin?" do
    expect(Admin.find('admin@example.com').super_admin?).to be(false)
    expect(Admin.find('all@example.com').super_admin?).to be(true)
  end

  describe "#super_admin=" do
    it "disable super admin flag" do
      expect { Admin.find('all@example.com').super_admin = false }.to_not raise_error
      admin = Admin.find('all@example.com')
      expect(admin.super_admin?).to be(false)
      expect(admin.superadmin).to be(false) if admin.has_superadmin_column?
    end

    it "should not delete 'ALL' domain" do
      Admin.find('all@example.com').super_admin = false
      expect(Domain.exists?('ALL')).to be(true)
    end

    it "enable super admin flag" do
      expect { Admin.find('admin@example.com').super_admin = true }.to_not raise_error
      admin = Admin.find('all@example.com')
      expect(admin.super_admin?).to be(true)
      expect(admin.superadmin).to be(true) if admin.has_superadmin_column?
    end
  end

  describe "#has_domain?" do
    it "returns true when the admin has privileges for the domain" do
      d = Domain.find('example.com')
      expect(Admin.find('admin@example.com').has_domain?(d)).to be(true)
    end

    it "returns false when the admin does not have privileges for the domain" do
      d = Domain.find('example.org')
      expect(Admin.find('admin@example.com').has_domain?(d)).to be(false)
    end

    it "returns true when super admin and exist domain" do
      d = Domain.find('example.com')
      expect(Admin.find('all@example.com').has_domain?(d)).to be(true)
    end

    it "returns true when super admin and another domain" do
      d = Domain.find('example.org')
      expect(Admin.find('all@example.com').has_domain?(d)).to be(true)
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
