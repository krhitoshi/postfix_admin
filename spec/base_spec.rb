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

  it "#admin_domains" do
    lambda { @base.admin_domains }.should_not raise_error
    lambda { @base.admin_domains('admin@example.com') }.should_not raise_error
  end
end
