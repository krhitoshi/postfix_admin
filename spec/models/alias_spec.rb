require File.join(__dir__, "..", "spec_helper")
require "postfix_admin/models/alias"

RSpec.describe PostfixAdmin::Alias do
  it "active" do
    domain = Domain.find('example.com')
    domain.rel_aliases << build(:alias, address: "non_active_alias@example.com",
                                        active: false)
    domain.save

    expect(Alias.find('user@example.com').active).to be(true)
    expect(Alias.find('alias@example.com').active).to be(true)
    expect(Alias.find('non_active_alias@example.com').active).to  be(false)
  end

  describe ".exists?" do
    it "returns true when exist alias and account" do
      expect(Alias.exists?('user@example.com')).to be(true)
      expect(Alias.exists?('alias@example.com')).to be(true)
    end

    it "returns false when unknown alias" do
      expect(Alias.exists?('unknown@unknown.example.com')).to be(false)
    end
  end

  describe ".mailbox?" do
    it "when there is same address in maiboxes returns true" do
      expect(Alias.find('user@example.com').mailbox?).to be(true)
    end

    it "when there is no same address in maiboxes returns false" do
      expect(Alias.find('alias@example.com').mailbox?).to be(false)
    end
  end

  it "#pure" do
    expect(Alias.pure.exists?("alias@example.com")).to be(true)
    expect(Alias.pure.exists?("user@example.com")).to be(false)
    expect(Alias.pure.exists?("user2example.com")).to be(false)
  end

  it "forward" do
    expect(Alias.forward.exists?("alias@example.com")).to be(false)
    expect(Alias.forward.exists?("user@example.com")).to be(false)
    expect(Alias.forward.exists?("user2@example.com")).to be(true)
  end
end
