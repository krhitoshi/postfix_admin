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

  it "#new with database config" do
    lambda { PostfixAdmin::Base.new({'database' => 'mysql://postfix:password@localhost/postfix'}) }.should_not raise_error
  end

  it "Default configuration should be correct" do
    @base.config[:aliases].should == 30
    @base.config[:mailboxes].should == 30
    @base.config[:maxquota].should == 100
    @base.config[:mailbox_quota].should == 100 * 1024 * 1000
  end
end
