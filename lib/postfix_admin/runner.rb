require 'thor'
require 'postfix_admin'
require 'postfix_admin/cli'

class PostfixAdmin::Runner < Thor
  def initialize(*args)
    super
    @cli = PostfixAdmin::CLI.new
  end

  desc "summary", "Summarize the usage of PostfixAdmin"
  def summary
    @cli.show_summary
  end

  desc "show", "List of domains"
  def show(domain=nil)
    @cli.show_summary(domain)

    if domain
      @cli.show_domain_account(domain)
      @cli.show_domain_aliases(domain)
    else
      @cli.show_domain
      @cli.show_admin
    end
  end

  desc "setup", "Setup a domain"
  def setup_domain(domain=nil, password=nil)
    if domain && password
      admin = "admin@#{domain}"
      add_domain(domain)
      add_admin(admin, password)
      add_admin_domain(admin, domain)
    else
      exit_with_usage('setup', 'example.com password')
    end
  end

  desc "add_domain", "Add a domain"
  def add_domain(domain=nil)
    if domain
      if @cli.add_domain(domain)
        puts %Q!"#{domain}" is successfully registered.!
      end
    else
      exit_with_usage('add_domain', 'example.com')
    end
  end

  desc "delete_domain", "Delete a domain"
  def delete_domain(domain=nil)
    if domain
      if @cli.delete_domain(domain)
        puts %Q!"#{domain}" is successfully deleted.!
      end
    else
      exit_with_usage('delete_domain', 'example.com')
    end
  end

  desc "delete_admin", "Delete an admin"
  def delete_admin(user_name=nil)
    if user_name
      if @cli.delete_admin(user_name)
        puts %Q!"#{user_name}" is successfully deleted.!
      end
    else
      exit_with_usage('delete_admin', 'admin@example.com')
    end
  end

  desc "add_account", "Add an account"
  def add_account(address=nil,password=nil)
    if address && password
      if @cli.add_account(address, password)
        puts %Q!"#{address}" is successfully registered.!
      end
    else
      exit_with_usage('add_account', 'user@example.com password')
    end
  end

  desc "add_admin", "Add an admin user"
  def add_admin(user_name=nil, password=nil)
    if user_name && password
      if @cli.add_admin(user_name, password)
        puts %Q!"#{user_name}" is successfully registered as admin.!
      end
    else
      exit_with_usage('add_admin', 'user@example.com password')
    end
  end

  desc "add_admin_domain", "Add admin_domain"
  def add_admin_domain(user_name=nil, domain=nil)
    if user_name && domain
      if @cli.add_admin_domain(user_name, domain)
        puts %Q!"#{domain}" is appended in the domains of #{user_name}.!
      end
    else
      exit_with_usage('add_admin_domain', 'user@example.com example.com')
    end
  end

  desc "add_alias", "Add an alias"
  def add_alias(address=nil, goto=nil)
    if address && goto
      if @cli.add_alias(address, goto)
        puts %Q!"#{address}: #{goto}" is successfully registered as alias.!
      end
    else
      exit_with_usage('add_alias', 'alias@example.com goto@example.com')
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
