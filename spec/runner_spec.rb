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
    it "#show shows information of example.com" do
     capture(:stdout){ Runner.start(["show"]) }.should =~ /example.com.+30.+30.+100/
    end

    it "#show shows information of admin@example.com" do
      capture(:stdout){ Runner.start(["show"]) }.should =~ /admin@example.com.+1.+password/
    end
  end

  it "#setup" do
    capture(:stdout){ Runner.start(['setup', 'example.net', 'password']) }.should =~ EX_REGISTERED
    capture(:stdout){ Runner.start(['delete_domain', 'example.net']) }.should =~ EX_DELETED
  end

  describe "#add_alias and #delete_alias" do
    it "You can add and delete an new alias." do
      capture(:stdout){ Runner.start(['add_alias', 'alias@example.com', 'goto@example.jp']) }.should =~ EX_REGISTERED
      capture(:stdout){ Runner.start(['delete_alias', 'alias@example.com']) }.should =~ EX_DELETED
    end

    it "You can not delete mailbox alias." do
      capture(:stderr){ Runner.start(['delete_alias', 'user@example.com']) }.should =~ /Can not delete mailbox/
    end

    it "You can not add an alias for existed mailbox" do
      capture(:stderr){ Runner.start(['add_alias', 'user@example.com', 'goto@example.jp']) }.should =~ /mailbox user@example.com is already registered!/
    end
  end

  it "#add_admin and #delete_admin" do
    capture(:stdout){ Runner.start(['add_admin', 'admin@example.jp', 'password']) }.should =~ EX_REGISTERED
    capture(:stdout){ Runner.start(['add_admin_domain', 'admin@example.jp', 'example.com']) }.should =~ EX_REGISTERED
    capture(:stdout){ Runner.start(['delete_admin', 'admin@example.jp']) }.should =~ EX_DELETED
  end

  it "#add_account and #delete_account" do
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
