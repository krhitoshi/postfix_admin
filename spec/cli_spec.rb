
require 'postfix_admin/cli'

describe PostfixAdmin::CLI do
  before do
    @cli = PostfixAdmin::CLI.new
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
end
