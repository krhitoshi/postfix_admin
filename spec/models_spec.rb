require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/models'

describe PostfixAdmin::Admin do
  before do
    db_initialize
  end

  it "#super_admin?" do
    Admin.find('admin@example.com').super_admin?.should === false
    Admin.find('all@example.com').super_admin?.should === true
  end

  it "#super_admin=" do
    Admin.find('admin@example.com').super_admin = true
    Admin.find('admin@example.com').super_admin?.should === true

    Admin.find('all@example.com').super_admin = false
    Admin.find('all@example.com').super_admin?.should === false
  end
end

describe PostfixAdmin::Domain do
  before do
    db_initialize
    @base = PostfixAdmin::Base.new({'database' => 'sqlite::memory:'})
  end

  describe "#num_total_aliases" do
    it "when only alias@example.com" do
      Domain.num_total_aliases.should be(1)
    end

    it "should increase one if you add an alias" do
      @base.add_alias('new_alias@example.com', 'goto@example.jp')
      Domain.num_total_aliases.should be(2)
    end

    it "should not increase if you add an account" do
      @base.add_account('user2@example.com', 'password')
      Domain.num_total_aliases.should be(1)
    end
  end
end
