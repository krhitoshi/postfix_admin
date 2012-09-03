require 'postfix_admin/base'

describe PostfixAdmin::Base do
  before do
    @base = PostfixAdmin::Base.new({'database' => 'mysql://postfix:password@localhost/postfix'})
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

  it "#domains" do
    lambda { @base.domains }.should_not raise_error
  end

  it "#admins" do
    lambda { @base.admins }.should_not raise_error
  end

  it "#mailboxes" do
    lambda { @base.mailboxes }.should_not raise_error
    lambda { @base.mailboxes('example.com') }.should_not raise_error
  end

  it "#aliases" do
    lambda { @base.aliases }.should_not raise_error
    lambda { @base.aliases('example.com') }.should_not raise_error
  end
  it "#admin_domains" do
    lambda { @base.admin_domains }.should_not raise_error
    lambda { @base.admin_domains('admin@example.com') }.should_not raise_error
  end

  it "#domain_exist?" do
    @base.domain_exist?('example.com').should be_true
  end

  it "#alias_exist?" do
    @base.alias_exist?('user@example.com').should be_true
  end

  it "#admin_exist?" do
    @base.admin_exist?('admin@example.com').should be_true
  end

  it "#admin_domain_exist?" do
    @base.admin_domain_exist?('admin@example.com', 'example.com').should be_true
  end

  it "#add_domain" do
    num_domains = @base.domains.count
    @base.add_domain('example.net')
    (@base.domains.count - num_domains).should be(1)
    @base.delete_domain('example.net')
  end

  describe "#add_domain" do
    before do
      @base.add_domain('example.net')
    end

    after do
      @base.delete_domain('example.net')
    end

    it "#add_admin" do
      num_admins = @base.admins.count
      @base.add_admin('admin@example.net', 'password')
      (@base.admins.count - num_admins).should be(1)
    end

    it "#add_account, add_alias" do
      num_mailboxes = @base.mailboxes.count
      num_aliases   = @base.aliases.count
      @base.add_account('user@example.net', 'password')
      (@base.mailboxes.count - num_mailboxes).should be(1)
      (@base.aliases.count - num_aliases).should be(1)
      lambda { @base.add_alias('user@example.net', 'goto@example.jp') }.should_not raise_error
    end

    it "#add_admin_domain" do
      @base.add_admin('admin@example.net', 'password')
      @base.add_admin_domain('admin@example.net', 'example.net')
      @base.admin_domains('admin@example.net').find do |admin_domain|
        admin_domain.domain == 'example.net'
      end.should be_true
    end
  end

  describe "#delete_domain" do
    before do
      @base.add_domain('example.net')
      @base.add_admin('admin@example.net', 'password')

      @base.add_account('user@example.net', 'password')
      @base.add_account('user2@example.net', 'password')
      @base.add_account('user3@example.net', 'password')

      @base.add_admin_domain('admin@example.net', 'example.net')

      @base.delete_domain('example.net')
    end

    it "no domain" do
      @base.domain_exist?('example.net').should be_false
    end

    it "no admin (admin@)" do
      @base.admin_exist?('admin@example.net').should be_false
    end

    it "no maiboxes" do
      @base.mailboxes('example.net').count.should be(0)
    end

    it "no admin_domain" do
      @base.admin_domain_exist?('admin@example.net', 'example.net').should be_false
    end
  end
end
