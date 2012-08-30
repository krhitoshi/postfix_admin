require 'thor'
require 'postfix_admin'
require 'postfix_admin/cli'

class PostfixAdmin::Runner < Thor
  def initialize(*args)
    super
    @cli = PostfixAdmin::CLI.new
  end
  desc "show", "List of domains"
  def show(domain=nil)
    if domain
      @cli.show_domain_account(domain)
    else
      @cli.show_domain
      @cli.show_admin
    end
  end

  desc "add_domain", "add a domain"
  def add_domain(domain=nil)
    if domain
      if @cli.add_domain(domain)
        puts %Q!"#{domain}" is successfully registered.!
      end
      @cli.show_domain
    else
      exit_with_usage('add_domain', 'example.com')
    end
  end

  desc "delete_domain", "delete a domain"
  def delete_domain(domain=nil)
    if domain
      if @cli.delete_domain(domain)
        puts %Q!"#{domain}" is successfully deleted.!
      end
      @cli.show_domain
    else
      exit_with_usage('delete_domain', 'example.com')
    end
  end

  desc "add_account", "add an account"
  def add_account(address=nil,password=nil)
    if address && password
      if @cli.add_account(address, password)
        puts %Q!"#{address}" is successfully registered.!
      end
      @cli.show_domain_account(address.split(/@/)[1])
    else
      exit_with_usage('add_account', 'user@example.com password')
    end
  end

  desc "add_admin", "add an admin user"
  def add_admin(user_name=nil, password=nil)
    if user_name && password
      if @cli.add_admin(user_name, password)
        puts %Q!"#{user_name}" is successfully registered as admin.!
      end
      @cli.show_admin
    else
      exit_with_usage('add_admin', 'user@example.com password')
    end
  end

  desc "add_admin_domain", "add admin_domain"
  def add_admin_domain(user_name=nil, domain=nil)
    if user_name && domain
      if @cli.add_admin_domain(user_name, domain)
        puts %Q!"#{domain}" is appended in the domains of #{user_name}.!
      end
      @cli.show_admin_domain(user_name)
    else
      exit_with_usage('add_admin_domain', 'user@example.com example.com')
    end
  end

  desc "add_alias", "add an alias"
  def add_alias(address=nil, goto=nil)
    if address && goto
      if @cli.add_alias(address, goto)
        puts %Q!"#{address}: #{goto}" is successfully registered as alias.!
      end
      @cli.show_domain_account(address.split(/@/)[1])
    else
      exit_with_usage('add_alias', 'user@example.com goto@example.com')
    end
  end

  desc "version", "Show postfix_admin version"
  def version
    require 'postfix_admin/version'
    say "postfix_admin #{PostfixAdmin::VERSION}"
  end

  private

  def exit_with_usage(subcommand, args)
    say "Usage: postfix_admin #{subcommand} #{args}"
    exit
  end
end
