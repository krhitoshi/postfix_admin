require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/runner'

describe PostfixAdmin::Runner do
  before do
    db_initialize
  end

  it "#version" do
    capture(:stdout){ Runner.start(["version"]) }.should =~ /postfix_admin \d+\.\d+\.\d/
  end

  it "#summary" do
    capture(:stdout){ Runner.start(["summary"]) }.should =~ /\[Summary\]/
  end

  describe "#show" do
    it "shows information of example.com" do
     capture(:stdout){ Runner.start(["show"]) }.should =~ /example.com.+30.+30.+100/
    end

    it "shows information of admin@example.com" do
      capture(:stdout){ Runner.start(["show"]) }.should =~ /admin@example.com.+1.+password/
    end
  end

  it "setup" do
    capture(:stdout){ Runner.start(['setup', 'example.net', 'password']) }.should =~ EX_REGISTERED
    capture(:stdout){ Runner.start(['delete_domain', 'example.net']) }.should =~ EX_DELETED
  end

  describe "super_admin" do
    it "can enable super admin flag of an admin" do
      capture(:stdout){ Runner.start(['super', 'admin@example.com']) }.should =~ /Successfully enabled/
    end

    it "can disable super admin flag of an admin (--disable)" do
      capture(:stdout){ Runner.start(['super', 'admin@example.com', '--disable']) }.should =~ /Successfully disabled/
    end

    it "can use -d option as --disable" do
      capture(:stdout){ Runner.start(['super', 'admin@example.com', '-d']) }.should =~ /Successfully disabled/
    end
  end

  describe "admin_passwd" do
    it "can change password of an admin" do
      capture(:stdout){ Runner.start(['admin_passwd', 'admin@example.com', 'new_password']) }.should =~ /successfully changed/
    end

    it "can not use too short password (< 5)" do
      capture(:stderr){ Runner.start(['admin_passwd', 'admin@example.com', '124']) }.should =~ /too short/
    end

    it "can not use for unknown admin" do
      capture(:stderr){ Runner.start(['admin_passwd', 'unknown@example.com', 'new_password']) }.should =~ /Could not find/
    end
  end

  describe "account_passwd" do
    it "can change password of an account" do
      capture(:stdout){ Runner.start(['account_passwd', 'user@example.com', 'new_password']) }.should =~ /successfully changed/
    end

    it "can not use too short password (< 5)" do
      capture(:stderr){ Runner.start(['account_passwd', 'user@example.com', '1234']) }.should =~ /too short/
    end

    it "can not use for unknown account" do
      capture(:stderr){ Runner.start(['account_passwd', 'unknown@example.com', 'new_password']) }.should =~ /Could not find/
    end
  end

  describe "add_alias and delete_alias" do
    it "can add and delete an new alias." do
      capture(:stdout){ Runner.start(['add_alias', 'new_alias@example.com', 'goto@example.jp']) }.should =~ EX_REGISTERED
      capture(:stdout){ Runner.start(['delete_alias', 'new_alias@example.com']) }.should =~ EX_DELETED
    end

    it "can not delete mailbox alias." do
      capture(:stderr){ Runner.start(['delete_alias', 'user@example.com']) }.should =~ /Can not delete mailbox/
    end

    it "can not add an alias for existed mailbox" do
      capture(:stderr){ Runner.start(['add_alias', 'user@example.com', 'goto@example.jp']) }.should =~ /mailbox user@example.com is already registered!/
    end
  end

  describe "add_admin" do
    it "can add an new admin" do
      capture(:stdout){ Runner.start(['add_admin', 'admin@example.jp', 'password']) }.should =~ EX_REGISTERED
    end

    it "--super option" do
      capture(:stdout){ Runner.start(['add_admin', 'admin@example.jp', 'password', '--super']) }.should =~ /registered as a super admin/
    end

    it "-s (--super) option" do
      capture(:stdout){ Runner.start(['add_admin', 'admin@example.jp', 'password', '-s']) }.should =~ /registered as a super admin/
    end
  end

  it "add_admin_domain" do
    capture(:stdout){ Runner.start(['add_admin_domain', 'admin@example.com', 'example.org']) }.should =~ EX_REGISTERED
  end

  it "delete_admin" do
    capture(:stdout){ Runner.start(['delete_admin', 'admin@example.com']) }.should =~ EX_DELETED
  end

  it "add_account and delete_account" do
    capture(:stdout){ Runner.start(['add_account', 'user2@example.com', 'password']) }.should =~ EX_REGISTERED
    capture(:stdout){ Runner.start(['delete_account', 'user2@example.com']) }.should =~ EX_DELETED
  end

  it "add and delete methods" do
    lambda { Runner.start(['add_domain', 'example.net']) }.should_not raise_error
    Runner.start(['add_admin', 'admin@example.net', 'password'])
    Runner.start(['add_admin_domain', 'admin@example.net', 'example.net'])

    lambda { Runner.start(['add_account', 'user1@example.net', 'password']) }.should_not raise_error
    lambda { Runner.start(['add_account', 'user2@example.net', 'password']) }.should_not raise_error
    lambda { Runner.start(['delete_domain', 'example.net']) }.should_not raise_error
  end
end
