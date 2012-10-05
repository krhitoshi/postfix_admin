
require 'postfix_admin/cli'

describe PostfixAdmin::CLI do
  before do
    db_initialize
    @cli = PostfixAdmin::CLI.new
  end

  it "#show_domain" do
    lambda { @cli.show_domain }.should_not raise_error
    capture(:stdout){ @cli.show_domain }.should_not =~ /ALL/
  end

  it "#show_summary" do
    lambda { @cli.show_summary }.should_not raise_error
    lambda { @cli.show_summary('unknown.example.com') }.should raise_error Error
  end

  it "#show_admin" do
    lambda { @cli.show_admin }.should_not raise_error
  end

  it "#show_domain_account" do
    lambda { @cli.show_domain_account('example.com') }.should_not raise_error
    lambda { @cli.show_domain_account('unknown.example.com') }.should raise_error Error
  end

  it "#show_admin_domain" do
    lambda { @cli.show_admin_domain('admin@example.com') }.should_not raise_error
  end

  it "#show_domain_aliases" do
    lambda { @cli.show_domain_aliases('example.com') }.should_not raise_error
    lambda { @cli.show_domain_aliases('unknown.example.com') }.should raise_error Error
  end

  it "#admin_exist?" do
    Admin.exist?('admin@example.com').should be_true
    Admin.exist?('admin@example.net').should be_false
  end

  it "#alias_exit?" do
    Alias.exist?('user@example.com').should be_true
    Alias.exist?('unknown@example.com').should be_false
  end

  it "#add_admin and #delete_admin" do
    lambda { @cli.add_admin('common@example.net', 'password') }.should_not raise_error
    Admin.exist?('common@example.net').should be_true
    lambda { @cli.delete_admin('common@example.net') }.should_not raise_error
    Admin.exist?('common@example.net').should be_false
  end

  it "#add_alias and #delete_alias" do
    lambda { @cli.add_alias('user@example.com', 'goto@example.jp') }.should raise_error
    lambda { @cli.delete_alias('user@example.com') }.should raise_error
    lambda { @cli.delete_alias('unknown@example.com') }.should raise_error

    lambda { @cli.add_alias('new_alias@example.com', 'goto@example.jp') }.should_not raise_error
    Alias.exist?('new_alias@example.com').should be_true

    lambda { @cli.delete_alias('new_alias@example.com') }.should_not raise_error
    Alias.exist?('new_alias@example.com').should be_false
  end

  it "add and delete methods" do
    lambda { @cli.add_domain('example.net') }.should_not raise_error

    lambda { @cli.add_admin('admin@example.net', 'password') }.should_not raise_error
    lambda { @cli.add_admin_domain('admin@example.net', 'example.net') }.should_not raise_error

    @cli.add_admin('admin2@example.net', 'password')
    @cli.add_admin_domain('admin2@example.net', 'example.net')

    @cli.add_admin('common@example.net', 'password')
    @cli.add_admin_domain('common@example.net', 'example.com')
    @cli.add_admin_domain('common@example.net', 'example.net')
    lambda { @cli.delete_admin('common@example.net') }.should_not raise_error
    Admin.exist?('common@example.net').should be_false

    @cli.add_admin('common@example.net', 'password')
    @cli.add_admin_domain('common@example.net', 'example.com')
    @cli.add_admin_domain('common@example.net', 'example.net')

    lambda { @cli.add_account('user1@example.net', 'password') }.should_not raise_error
    lambda { @cli.add_account('user2@example.net', 'password') }.should_not raise_error

    lambda { @cli.delete_domain('example.net') }.should_not raise_error
    Admin.exist?('admin@example.net').should be_false
    Admin.exist?('admin2@example.net').should be_false

    Admin.exist?('common@example.net').should be_true
    lambda { @cli.delete_admin('common@example.net') }.should_not raise_error
    Admin.exist?('common@example.net').should be_false
  end
end
