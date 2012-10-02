require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/runner'

describe PostfixAdmin::Runner do
  before do
    db_initialize
  end

  it "#version" do
    capture(:stdout){ PostfixAdmin::Runner.start(["version"]) }.should =~ /postfix_admin \d+\.\d+\.\d/
  end

  it "#summary" do
    capture(:stderr){ PostfixAdmin::Runner.start(["summary"]) }.should_not =~ /Could not find task/
  end

  describe "#show" do
    it "#show shows information of example.com" do
     capture(:stdout){ PostfixAdmin::Runner.start(["show"]) }.should =~ /example.com.+30.+30.+100/
    end

    it "#show shows information of admin@example.com" do
      capture(:stdout){ PostfixAdmin::Runner.start(["show"]) }.should =~ /admin@example.com.+1.+password/
    end
  end

  it "#setup" do
    capture(:stdout){ PostfixAdmin::Runner.start(['setup', 'example.net', 'password']) }.should =~ /successfully registered/
    capture(:stdout){ PostfixAdmin::Runner.start(['delete_domain', 'example.net']) }.should =~ /successfully deleted/
  end

  describe "#add_alias and #delete_alias" do
    it "You can add and delete an new alias." do
      lambda { PostfixAdmin::Runner.start(['add_alias', 'alias@example.com', 'goto@example.jp']) }.should_not raise_error
      lambda { PostfixAdmin::Runner.start(['delete_alias', 'alias@example.com']) }.should_not raise_error
    end

    it "You can not delete mailbox alias." do
      capture(:stderr){ PostfixAdmin::Runner.start(['delete_alias', 'user@example.com']) }.should =~ /Can not delete mailbox/
    end

    it "You can not add an alias for existed mailbox" do
      capture(:stderr){ PostfixAdmin::Runner.start(['add_alias', 'user@example.com', 'goto@example.jp']) }.should =~ /mailbox user@example.com is already registered!/
    end
  end

  it "#add_admin and #delete_admin" do
    capture(:stderr){ PostfixAdmin::Runner.start(['add_admin', 'admin@example.jp', 'password']) }.should_not =~ /Could not find task/
    capture(:stderr){ PostfixAdmin::Runner.start(['add_admin_domain', 'admin@example.jp', 'example.com']) }.should_not =~ /Could not find task/
    capture(:stderr){ PostfixAdmin::Runner.start(['delete_admin', 'admin@example.jp']) }.should_not =~ /Could not find task/
  end

  it "#add_account and #delete_account" do
    capture(:stderr){ PostfixAdmin::Runner.start(['add_account', 'user2@example.com', 'password']) }.should_not =~ /Could not find task/
    capture(:stderr){ PostfixAdmin::Runner.start(['delete_account', 'user2@example.com']) }.should_not =~ /Could not find task/
  end

  it "add and delete methods" do
    lambda { PostfixAdmin::Runner.start(['add_domain', 'example.net']) }.should_not raise_error
    PostfixAdmin::Runner.start(['add_admin', 'admin@example.net', 'password'])
    PostfixAdmin::Runner.start(['add_admin_domain', 'admin@example.net', 'example.net'])

    lambda { PostfixAdmin::Runner.start(['add_account', 'user1@example.net', 'password']) }.should_not raise_error
    lambda { PostfixAdmin::Runner.start(['add_account', 'user2@example.net', 'password']) }.should_not raise_error
    lambda { PostfixAdmin::Runner.start(['delete_domain', 'example.net']) }.should_not raise_error
  end
end
