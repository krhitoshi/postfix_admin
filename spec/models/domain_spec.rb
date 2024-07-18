require File.join(__dir__, "..", "spec_helper")
require "postfix_admin/models/domain"

RSpec.describe PostfixAdmin::Domain do
  before do
    @base = PostfixAdmin::Base.new({'database' => 'sqlite::memory:'})
    @domain_name = "example.com"
    @domain = Domain.find(@domain_name)
  end

  it ".exists?" do
    expect(Domain.exists?('example.com')).to be(true)
    expect(Domain.exists?('example.org')).to be(true)
    expect(Domain.exists?('unknown.example.com')).to be(false)
  end

  it "active" do
    expect(@domain.active).to be(true)
    expect(Domain.find('example.org').active).to be(true)

    create(:domain, domain: "non-active.example.com", active: false)
    expect(Domain.find('non-active.example.com').active).to be(false)
  end

  it "#mailbox_count" do
    count = Mailbox.where(domain: @domain_name).count
    expect(count).not_to eq(0)
    expect(@domain.mailbox_count).to eq(count)

    # Add a mailbox
    @domain.rel_mailboxes << build(:mailbox, local_part: "new-user")
    expect(@domain.mailbox_count).to eq(count + 1)

    # Delete all mailboxes
    @domain.rel_mailboxes.delete_all
    expect(@domain.mailbox_count).to eq(0)
  end

  it "#maxquota_unlimited?" do
    expect(@domain.maxquota_unlimited?).to be(false)
    @domain.update(maxquota: Domain::UNLIMITED_MAXQUOTA)
    expect(@domain.reload.maxquota_unlimited?).to be(true)
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
      @base.add_account('new-user@example.com', 'password')
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
