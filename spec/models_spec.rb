require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'active_record'
require 'postfix_admin/application_record'
require 'postfix_admin/admin'
require 'postfix_admin/domain'
require 'postfix_admin/mailbox'
require 'postfix_admin/alias'
require 'postfix_admin/domain_admin'
require 'postfix_admin/log'
require 'postfix_admin/mail_domain'
require 'postfix_admin/quota'

describe PostfixAdmin::Admin do
  before do
    db_initialize
  end

  it ".exists?" do
    Admin.exists?('admin@example.com').should === true
    Admin.exists?('all@example.com').should === true
    Admin.exists?('unknown@example.com').should === false
  end

  it "active" do
    Admin.find('admin@example.com').active.should === true
    Admin.find('all@example.com').active.should === true
    non_active_admin = create_admin('non_active_admin@example.com', false)

    Admin.find('non_active_admin@example.com').active.should === false
  end

  it "#super_admin?" do
    Admin.find('admin@example.com').super_admin?.should === false
    Admin.find('all@example.com').super_admin?.should === true
  end

  describe "#super_admin=" do
    it "disable super admin flag" do
      lambda { Admin.find('all@example.com').super_admin = false }.should_not raise_error
      admin = Admin.find('all@example.com')
      admin.super_admin?.should === false
      admin.superadmin.should === false if admin.has_superadmin_column?
    end

    it "should not delete 'ALL' domain" do
      Admin.find('all@example.com').super_admin = false
      Domain.exists?('ALL').should be true
    end

    it "enable super admin flag" do
      lambda { Admin.find('admin@example.com').super_admin = true }.should_not raise_error
      admin = Admin.find('all@example.com')
      admin.super_admin?.should === true
      admin.superadmin.should === true if admin.has_superadmin_column?
    end
  end

  describe "#has_domain?" do
    it "returns true when the admin has privileges for the domain" do
      d = Domain.find('example.com')
      Admin.find('admin@example.com').has_domain?(d).should === true
    end

    it "returns false when the admin does not have privileges for the domain" do
      d = Domain.find('example.org')
      Admin.find('admin@example.com').has_domain?(d).should === false
    end

    it "returns true when super admin and exist domain" do
      d = Domain.find('example.com')
      Admin.find('all@example.com').has_domain?(d).should === true
    end

    it "returns true when super admin and another domain" do
      d = Domain.find('example.org')
      Admin.find('all@example.com').has_domain?(d).should === true
    end
  end
end

describe PostfixAdmin::Domain do
  before do
    db_initialize
    @base = PostfixAdmin::Base.new({'database' => 'sqlite::memory:'})
  end

  it ".exists?" do
    Domain.exists?('example.com').should === true
    Domain.exists?('example.org').should === true
    Domain.exists?('unknown.example.com').should === false
  end

  it "active" do
    Domain.find('example.com').active.should == true
    Domain.find('example.org').active.should == true

    create_domain('non-active.example.com', false)
    Domain.find('non-active.example.com').active.should == false
  end

  describe "#num_total_aliases and .num_total_aliases" do
    it "when only alias@example.com" do
      Alias.pure.count.should be(1)
      Domain.find('example.com').pure_aliases.count.should be(1)
    end

    it "should increase one if you add an alias" do
      @base.add_alias('new_alias@example.com', 'goto@example.jp')
      Alias.pure.count.should be(2)
      Domain.find('example.com').pure_aliases.count.should be(2)
    end

    it "should not increase if you add an account" do
      @base.add_account('user2@example.com', 'password')
      Alias.pure.count.should be(1)
      Domain.find('example.com').pure_aliases.count.should be(1)
    end

    it ".num_total_aliases should not increase if you add an account and an aliase for other domain" do
      @base.add_account('user@example.org', 'password')
      Alias.pure.count.should be(1)
      Domain.find('example.com').pure_aliases.count.should be(1)
      @base.add_alias('new_alias@example.org', 'goto@example.jp')
      Alias.pure.count.should be(2)
      Domain.find('example.com').pure_aliases.count.should be(1)
    end
  end
end

describe PostfixAdmin::Mailbox do
  before do
    db_initialize
  end

  it "active" do
    Mailbox.find('user@example.com').active.should == true
    domain = Domain.find('example.com')
    domain.rel_mailboxes << create_mailbox('non_active_user@example.com', nil, false)
    domain.save!

    Mailbox.find('non_active_user@example.com').active.should == false
  end

  it "can use long maildir" do
    domain = Domain.find('example.com')
    domain.rel_mailboxes << create_mailbox('long_maildir_user@example.com', 'looooooooooooong_path/example.com/long_maildir_user@example.com/')
    domain.save.should == true
  end

  describe ".exists?" do
    it "returns true for exist account (mailbox)" do
      Mailbox.exists?('user@example.com').should === true
    end

    it "returns false for alias" do
      Mailbox.exists?('alias@example.com').should === false
    end

    it "returns false for unknown account (mailbox)" do
      Mailbox.exists?('unknown@unknown.example.com').should === false
    end
  end
end

describe PostfixAdmin::Alias do
  before do
    db_initialize
  end

  it "active" do
    domain = Domain.find('example.com')
    domain.rel_aliases << create_alias('non_active_alias@example.com', false)
    domain.save

    Alias.find('user@example.com').active.should == true
    Alias.find('alias@example.com').active.should == true
    Alias.find('non_active_alias@example.com').active.should == false
  end

  describe ".exists?" do
    it "returns true when exist alias and account" do
      Alias.exists?('user@example.com').should === true
      Alias.exists?('alias@example.com').should === true
    end

    it "returns false when unknown alias" do
      Alias.exists?('unknown@unknown.example.com').should === false
    end
  end

  describe ".mailbox?" do
    it "when there is same address in maiboxes returns true" do
      Alias.find('user@example.com').mailbox?.should === true
    end

    it "when there is no same address in maiboxes returns false" do
      Alias.find('alias@example.com').mailbox?.should === false
    end
  end
end
