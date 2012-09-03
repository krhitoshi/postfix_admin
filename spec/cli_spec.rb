
require 'postfix_admin/cli'

describe PostfixAdmin::CLI do
  before do
    @cli = PostfixAdmin::CLI.new(File.join(File.dirname(__FILE__) , 'postfix_admin.conf'))
  end

  it "#show_domain" do
    lambda { @cli.show_domain }.should_not raise_error
  end

  it "#show_admin" do
    lambda { @cli.show_admin }.should_not raise_error
  end

  it "#show_domain_account" do
    lambda { @cli.show_domain_account('example.com') }.should_not raise_error
  end

  it "#show_admin_domain" do
    lambda { @cli.show_admin_domain('admin@example.com') }.should_not raise_error
  end

  it "add and delete methods" do
    lambda { @cli.add_domain('example.net') }.should_not raise_error

    lambda { @cli.add_admin('admin@example.net', 'password') }.should_not raise_error
    lambda { @cli.add_admin_domain('admin@example.net', 'example.net') }.should_not raise_error

    lambda { @cli.add_account('user1@example.net', 'password') }.should_not raise_error
    lambda { @cli.add_account('user2@example.net', 'password') }.should_not raise_error

    lambda { @cli.add_alias('user1@example.net', 'goto@example.jp') }.should_not raise_error
    lambda { @cli.delete_domain('example.net') }.should_not raise_error
  end
end
