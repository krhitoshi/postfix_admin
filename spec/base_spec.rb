require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/base'

describe PostfixAdmin::Base do
  before do
    db_initialize
    @base = PostfixAdmin::Base.new({'database' => 'mysql2://postfix:password@localhost/postfix'})
  end

  it "DEFAULT_CONFIG" do
    PostfixAdmin::Base::DEFAULT_CONFIG.should == {
        'database'  => 'mysql2://postfix:password@localhost/postfix',
        'aliases'   => 30,
        'mailboxes' => 30,
        'maxquota'  => 100,
        'scheme'    => 'CRAM-MD5',
        'passwordhash_prefix' => true
    }
  end

  it "#address_split" do
    @base.address_split('user@example.com').should == ['user', 'example.com']
  end

  it "#new without config" do
    lambda { PostfixAdmin::Base.new }.should raise_error(ArgumentError)
  end

  it "Default configuration should be correct" do
    @base.config[:aliases].should == 30
    @base.config[:mailboxes].should == 30
    @base.config[:maxquota].should == 100
    @base.config[:scheme].should == 'CRAM-MD5'
  end

  it "config database" do
    @base.config[:database].should == 'mysql2://postfix:password@localhost/postfix'
  end

  it "#domain_exists?" do
    Domain.exists?('example.com').should be true
  end

  it "#alias_exists?" do
    Alias.exists?('user@example.com').should be true
    Alias.exists?('unknown@example.com').should be false
  end

  it "#mailbox_exists?" do
    Mailbox.exists?('user@example.com').should be true
    Mailbox.exists?('unknown@example.com').should be false
  end

  it "#admin_exists?" do
    Admin.exists?('admin@example.com').should be true
    Admin.exists?('unknown_admin@example.com').should be false
  end

  describe "#add_domain" do
    it "can add a new domain" do
      num_domains = Domain.count
      @base.add_domain('example.net')
      (Domain.count - num_domains).should be(1)
    end

    it "can not add exist domain" do
      lambda { @base.add_domain('example.com') }.should raise_error Error
    end

    it "can not add invalid domain" do
      lambda { @base.add_domain('localhost') }.should raise_error Error
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

    it "refuse empty password" do
      lambda { @base.add_account('new_user@example.com', '') }.should raise_error Error
    end

    it "refuse nil password" do
      lambda { @base.add_account('new_user@example.com', nil) }.should raise_error Error
    end

    it "can not add account which hsas invalid address" do
      lambda { @base.add_account('invalid.example.com', 'password') }.should raise_error Error
    end

    it "can not add account for unknown domain" do
      lambda { @base.add_account('user@unknown.example.com', 'password') }.should raise_error Error
    end

    it "can not add account which has same address as exist mailbox" do
      lambda { @base.add_account('user@example.com', 'password') }.should raise_error Error
    end

    it "can not add account which has same address as exist alias" do
      lambda { @base.add_account('alias@example.com', 'password') }.should raise_error Error
    end
  end

  describe "#add_admin" do
    it "can add an new admin" do
      num_admins = Admin.count
      @base.add_admin('admin@example.net', 'password')
      Admin.exists?('admin@example.net').should be true
      (Admin.count - num_admins).should be(1)
    end

    it "refuse empty password" do
      lambda { @base.add_admin('admin@example.net', '') }.should raise_error Error
    end

    it "refuse nil password" do
      lambda { @base.add_admin('admin@example.net', nil) }.should raise_error Error
    end

    it "can not add exist admin" do
      lambda { @base.add_admin('admin@example.com', 'password') }.should raise_error Error
    end
  end

  describe "#add_admin_domain" do
    it "#add_admin_domain" do
      @base.add_admin_domain('admin@example.com', 'example.org')
      d = Domain.find('example.org')
      Admin.find('admin@example.com').has_domain?(d).should be true
    end

    it "can not add unknown domain for an admin" do
      lambda { @base.add_admin_domain('admin@example.com', 'unknown.example.com') }.should raise_error Error
    end

    it "can not add domain for unknown admin" do
      lambda { @base.add_admin_domain('unknown_admin@example.com', 'example.net') }.should raise_error Error
    end

    it "can not add a domain which the admin has already privileges for" do
      lambda { @base.add_admin_domain('admin@example.com', 'example.com') }.should raise_error Error
    end
  end

  describe "#delete_admin_domain" do
    it "#delete_admin_domain" do
      d = Domain.find('example.org')
      lambda { @base.delete_admin_domain('admin@example.com', 'example.com') }.should_not raise_error
      Admin.find('admin@example.com').has_domain?(d).should be false
    end

    it "can not delete not administrated domain" do
      lambda { @base.delete_admin_domain('admin@example.com', 'example.org') }.should raise_error Error
    end

    it "raise error when unknown admin" do
      lambda { @base.delete_admin_domain('unknown_admin@example.com', 'example.com') }.should raise_error Error
    end

    it "raise error when unknown domain" do
      lambda { @base.delete_admin_domain('admin@example.com', 'unknown.example.com') }.should raise_error Error
    end
 end

  describe "#add_alias" do
    it "can add a new alias" do
      num_aliases = Alias.count
      lambda { @base.add_alias('new_alias@example.com', 'goto@example.jp') }.should_not raise_error
      (Alias.count - num_aliases).should be(1)
      Alias.exists?('new_alias@example.com').should be true
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
      lambda { @base.delete_alias('alias@example.com') }.should_not raise_error
      Alias.exists?('alias@example.com').should be false
    end

    it "can not delete mailbox" do
      lambda { @base.delete_alias('user@example.com') }.should raise_error Error
    end

    it "can not delete unknown alias" do
      lambda { @base.delete_alias('unknown@example.com') }.should raise_error Error
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
      lambda { @base.delete_domain('example.com') }.should_not raise_error

      Domain.exists?('example.com').should be false
      Admin.exists?('admin@example.com').should be false

      Alias.where(domain: 'example.com').count.should be(0)
      Mailbox.where(domain: 'example.com').count.should be(0)

      DomainAdmin.where(username: 'admin@example.com',
                        domain: 'example.com').count.should be(0)
    end

    it "can not delete unknown domain" do
      lambda { @base.delete_domain('unknown.example.com') }.should raise_error Error
    end
  end

  describe "#delete_admin" do
    it "can delete an admin" do
      lambda { @base.delete_admin('admin@example.com') }.should_not raise_error
      Admin.exists?('admin@example.com').should be false
    end

    it "can not delete unknown admin" do
      lambda { @base.delete_admin('unknown_admin@example.com') }.should raise_error Error
    end
  end

  describe "#delete_account" do
    it "can delete an account" do
      lambda { @base.delete_account('user@example.com') }.should_not raise_error
      Mailbox.exists?('user@example.com').should be false
      Alias.exists?('user@example.com').should be false
    end

    it "can not delete unknown account" do
      lambda { @base.delete_account('unknown@example.com') }.should raise_error Error
    end
  end
end
