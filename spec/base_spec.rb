require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/base'

describe PostfixAdmin::Base do
  before do
    db_initialize
    @base = PostfixAdmin::Base.new({'database' => 'sqlite::memory:'})
  end

  it "DEFAULT_CONFIG" do
    PostfixAdmin::Base::DEFAULT_CONFIG.should == {
        'database'  => 'mysql://postfix:password@localhost/postfix',
        'aliases'   => 30,
        'mailboxes' => 30,
        'maxquota'  => 100
    }
  end

  it "#address_split" do
    @base.address_split('user@example.com').should == ['user', 'example.com']
  end

  it "#new without config" do
    lambda { PostfixAdmin::Base.new }.should raise_error(ArgumentError)
  end

  it "#new without database config" do
    lambda { PostfixAdmin::Base.new({}) }.should raise_error(ArgumentError)
  end

  it "Default configuration should be correct" do
    @base.config[:aliases].should == 30
    @base.config[:mailboxes].should == 30
    @base.config[:maxquota].should == 100
    @base.config[:mailbox_quota].should == 100 * 1024 * 1000
  end

  it "#admin_domains" do
    lambda { @base.admin_domains }.should_not raise_error
    lambda { @base.admin_domains('admin@example.com') }.should_not raise_error
  end

  it "#domain_exist?" do
    Domain.exist?('example.com').should be_true
  end

  it "#alias_exist?" do
    @base.alias_exist?('user@example.com').should be_true
    @base.alias_exist?('unknown@example.com').should be_false
  end

  it "#mailbox_exist?" do
    @base.mailbox_exist?('user@example.com').should be_true
    @base.mailbox_exist?('unknown@example.com').should be_false
  end

  it "#admin_exist?" do
    @base.admin_exist?('admin@example.com').should be_true
    @base.admin_exist?('unknown_admin@example.com').should be_false
  end

  it "#account_exist?" do
    @base.account_exist?('user@example.com').should be_true
    @base.account_exist?('unknown@example.com').should be_false
  end

  it "#admin_domain_exist?" do
    @base.admin_domain_exist?('admin@example.com', 'example.com').should be_true
    @base.admin_domain_exist?('admin@example.com', 'example.org').should be_false
    @base.admin_domain_exist?('unknown@example.com', 'example.com').should be_false
  end

  describe "#add_domain" do
    it "can add a new domain" do
      num_domains = Domain.count
      @base.add_domain('example.net')
      (Domain.count - num_domains).should be(1)
    end

    it "can not add exist domain" do
      lambda{ @base.add_domain('example.com') }.should raise_error Error
    end

    it "can not add invalid domain" do
      lambda{ @base.add_domain('localhost') }.should raise_error Error
    end
  end

  describe "#add_account" do
    it "can add a new account" do
      num_mailboxes = Mailbox.count
      num_aliases   = Alias.count
      @base.add_account('new_user@example.com', 'password')
      (Mailbox.count - num_mailboxes).should be(1)
        (Alias.count - num_aliases).should be(1)
    end

    it "can not add account which hsas invalid address" do
      lambda{ @base.add_account('invalid.example.com', 'password') }.should raise_error Error
    end

    it "can not add account for unknown domain" do
      lambda{ @base.add_account('user@unknown.example.com', 'password') }.should raise_error Error
    end

    it "can not add account which has same address as exist mailbox" do
      lambda{ @base.add_account('user@example.com', 'password') }.should raise_error Error
    end

    it "can not add account which has same address as exist alias" do
      lambda{ @base.add_account('alias@example.com', 'password') }.should raise_error Error
    end
  end

  describe "#add_admin" do
    it "can add an new admin" do
      num_admins = Admin.count
      @base.add_admin('admin@example.net', 'password')
      @base.admin_exist?('admin@example.net').should be_true
      (Admin.count - num_admins).should be(1)
    end

    it "can not add exist admin" do
      lambda{ @base.add_admin('admin@example.com', 'password') }.should raise_error Error
    end
  end

  describe "#add_admin_domain" do
    it "#add_admin_domain" do
      @base.add_admin_domain('admin@example.com', 'example.org')
      @base.admin_domains('admin@example.com').find do |admin_domain|
        admin_domain.domain_name == 'example.org'
      end.should be_true
    end

    it "can not add unknown domain for an admin" do
      lambda{ @base.add_admin_domain('admin@example.com', 'unknown.example.com') }.should raise_error Error
    end

    it "can not add domain for unknown admin" do
      lambda{ @base.add_admin_domain('unknown_admin@example.com', 'example.net') }.should raise_error Error
    end

    it "can not add a domain which the admin has already privileges for" do
      lambda{ @base.add_admin_domain('admin@example.com', 'example.com') }.should raise_error Error
    end
  end

  describe "#add_alias" do
    it "can add a new alias" do
      num_aliases   = Alias.count
      lambda { @base.add_alias('new_alias@example.com', 'goto@example.jp') }.should_not raise_error
      (Alias.count - num_aliases).should be(1)
      @base.alias_exist?('new_alias@example.com').should be_true
    end

    it "can not add an alias which has a same name as a mailbox" do
      lambda { @base.add_alias('user@example.com', 'goto@example.jp') }.should raise_error Error
    end

    it "can not add an alias which has a sama name as other alias" do
      @base.add_alias('new_alias@example.com', 'goto@example.jp')
      lambda { @base.add_alias('new_alias@example.com', 'goto@example.jp') }.should raise_error Error
    end

    it "can not add an alias of unknown domain" do
      lambda { @base.add_alias('new_alias@unknown.example.com', 'goto@example.jp') }.should raise_error Error
    end
  end

  describe "#delete_alias" do
    it "can delete an alias" do
      lambda{ @base.delete_alias('alias@example.com') }.should_not raise_error
      @base.alias_exist?('alias@example.com').should be_false
    end

    it "can not delete mailbox" do
      lambda{ @base.delete_alias('user@example.com') }.should raise_error Error
    end

    it "can not delete unknown alias" do
      lambda{ @base.delete_alias('unknown@example.com') }.should raise_error Error
    end
  end

  describe "#delete_domain" do
    before do
      @base.add_account('user2@example.com', 'password')
      @base.add_account('user3@example.com', 'password')

      @base.add_alias('alias2@example.com', 'goto2@example.jp')
      @base.add_alias('alias3@example.com', 'goto3@example.jp')
    end

    it "can delete a domain" do
      lambda{ @base.delete_domain('example.com') }.should_not raise_error

      Domain.exist?('example.com').should be_false
      @base.admin_exist?('admin@example.com').should be_false

      Alias.all(:domain_name => 'example.com').count.should be(0)
      Mailbox.all(:domain_name => 'example.com').count.should be(0)

      @base.admin_domain_exist?('admin@example.com', 'example.com').should be_false
    end

    it "can not delete unknown domain" do
      lambda{ @base.delete_domain('unknown.example.com') }.should raise_error Error
    end
  end

  describe "#delete_admin" do
    it "can delete an admin" do
      lambda{ @base.delete_admin('admin@example.com') }.should_not raise_error
      @base.admin_exist?('admin@example.com').should be_false
    end

    it "can not delete unknown admin" do
      lambda{ @base.delete_admin('unknown_admin@example.com') }.should raise_error Error
    end
  end

  describe "#delete_account" do
    it "can delete an account" do
      lambda{ @base.delete_account('user@example.com') }.should_not raise_error
      @base.account_exist?('user@example.com').should be_false
      @base.mailbox_exist?('user@example.com').should be_false
      @base.alias_exist?('user@example.com').should be_false
    end

    it "can not delete unknown account" do
      lambda{ @base.delete_account('unknown@example.com') }.should raise_error Error
    end
  end
end
