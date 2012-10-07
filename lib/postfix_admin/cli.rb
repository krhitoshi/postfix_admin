require 'yaml'
require 'postfix_admin'

module PostfixAdmin
  class CLI
    CONFIG_FILE = '~/.postfix_admin.conf'
    MIN_NUM_PASSWORD_CHARACTER = 5

    def initialize
      @config = load_config
      @base = PostfixAdmin::Base.new(@config)
    end

    def show(domain)
      show_summary(domain)

      if domain
        show_domain_account(domain)
        show_domain_aliases(domain)
      else
        show_domain
        show_admin
      end
    end

    def show_summary(domain_name=nil)
      title = "Summary"
      if domain_name
        domain_check(domain_name)
        title = "Summary of #{domain_name}"
      end

      report(title) do
        if domain_name
          domain = Domain.find(domain_name)
          puts "Mailboxes : %4d"    % domain.mailboxes.count
          puts "Aliases   : %4d"    % domain.num_total_aliases
          puts "Quota     : %4d MB" % domain.maxquota
        else
          puts "Domains   : %4d" % Domain.all_without_special_domain.count
          puts "Admins    : %4d" % Admin.count
          puts "Mailboxes : %4d" % Mailbox.count
          puts "Aliases   : %4d" % Domain.num_total_aliases
        end
      end
    end

    def setup_domain(domain, password)
      admin = "admin@#{domain}"
      add_domain(domain)
      add_admin(admin, password)
      add_admin_domain(admin, domain)
    end

    def show_domain
      index = " No. Domain                Aliases   Mailboxes     Quota (MB)"
      report('Domains', index) do
        Domain.all_without_special_domain.each_with_index do |d, i|
          puts "%4d %-20s %3d /%3d   %3d /%3d %10d" %
            [i+1, d.domain_name, d.num_total_aliases, d.maxaliases,
             d.mailboxes.count, d.maxmailboxes, d.maxquota]
        end
      end
    end

    def add_domain(domain)
      if @base.add_domain(domain)
        puts %Q!"#{domain}" was successfully registered.!
      end
    end

    def super_admin(user_name, disable)
      unless Admin.exist?(user_name)
        raise Error, "Could not find admin #{user_name}"
      end

      if disable
        Admin.find(user_name).super_admin = false
        puts "Successfully disabled super admin flag of #{user_name}"
      else
        Admin.find(user_name).super_admin = true
        puts "Successfully enabled super admin flag of #{user_name}"
      end
    end

    def change_admin_password(user_name, password)
      change_password(Admin, user_name, password)
    end

    def change_account_password(user_name, password)
      change_password(Mailbox, user_name, password)
    end

    def delete_domain(domain)
      if @base.delete_domain(domain)
        puts %Q!"#{domain}" was successfully deleted.!
      end
    end

    def show_admin
      if Admin.count == 0
        puts "\nNo admin in database"
        return
      end

      index = " No. Admin                              Domains Password"
      report("Admin", index) do
        Admin.all.each_with_index do |a, i|
          domains = a.super_admin? ? 'Super admin' : a.domains.count
          puts "%4d %-30s %11s %s" % [i+1, a.username, domains, a.password]
        end
      end
    end

    def show_domain_account(domain)
      domain_check(domain)

      mailboxes = Domain.find(domain).mailboxes
      if mailboxes.count == 0
        puts "\nNo address in #{domain}"
        return
      end

      index = " No. Email                           Quota (MB) Password"
      report("Accounts", index) do
        mailboxes.each_with_index do |m, i|
          quota = m.quota.to_f/1024000.0
          puts "%4d %-30s  %10.1f %s" % [i+1, m.username, quota, m.password]
        end
      end
    end

    def show_domain_aliases(domain)
      domain_check(domain)

      aliases = Domain.find(domain).aliases.find_all do |mail_alias|
        mail_alias.address != mail_alias.goto
      end

      if aliases.count == 0
        puts "\nNo aliases in #{domain}"
        return
      end
      index = " No. Address                        Go to"
      report("Aliases", index) do
        aliases.each_with_index do |a, i|
          puts "%4d %-30s %s" % [i+1, a.address, a.goto]
        end
      end
    end

    def show_admin_domain(user_name)
      admin = Admin.find(user_name)
      if admin.domains.count == 0
        puts "\nNo domain in database"
        return
      end
      report("Domains (#{user_name})", " No. Domain") do
        admin.domains.each_with_index do |d, i|
          puts "%4d %-20s" % [i+1, d.domain_name]
        end
      end
    end

    def add_admin(user_name, password, super_admin=false)
      validate_password(password)
      if @base.add_admin(user_name, password)
        if super_admin
          Admin.find(user_name).super_admin = true
          puts_registered(user_name, "a super admin")
        else
          puts_registered(user_name, "an admin")
        end
      end
    end

    def add_admin_domain(user_name, domain)
      if @base.add_admin_domain(user_name, domain)
        puts_registered(domain, "a domain of #{user_name}")
      end
    end

    def add_account(address, password)
      validate_password(password)
      if @base.add_account(address, password)
        puts_registered(address, "an account")
      end
    end

    def add_alias(address, goto)
      if @base.add_alias(address, goto)
        puts_registered("#{address}: #{goto}", "an alias")
      end
    end

    def delete_alias(address)
      puts_deleted(address) if @base.delete_alias(address)
    end

    def delete_admin(user_name)
      puts_deleted(user_name) if @base.delete_admin(user_name)
    end

    def delete_account(address)
      puts_deleted(address) if @base.delete_account(address)
    end

    private

    def puts_registered(name, as_str)
      puts %Q!"#{name}" was successfully registered as #{as_str}.!
    end

    def puts_deleted(name)
      puts %Q!"#{name}" was successfully deleted.!
    end

    def config_file
      config_file = File.expand_path(CONFIG_FILE)
    end

    def load_config
      unless File.exist?(config_file)
        create_config(config_file)
        puts "configure file: #{config_file} was generated.\nPlease execute after edit it."
        exit
      end
      open(config_file) do |f|
        YAML.load(f.read)
      end
    end

    def create_config(config_file)
      open(config_file, 'w') do |f|
        f.write PostfixAdmin::Base::DEFAULT_CONFIG.to_yaml
      end
      File.chmod(0600, config_file)
    end

    def print_line
      puts "-"*100
    end

    def report(title, index=nil)
      puts "\n[#{title}]"
      print_line if index
      puts index if index
      print_line
      yield
      print_line
    end

    def domain_check(domain_name)
      unless Domain.exist?(domain_name)
        raise Error, %Q!Could not find domain "#{domain_name}"!
      end
    end

    def validate_password(password)
      if password.size < MIN_NUM_PASSWORD_CHARACTER
        raise ArgumentError, "Password is too short. It should be larger than #{MIN_NUM_PASSWORD_CHARACTER}"
      end
    end

    def change_password(klass, user_name, password)
      unless klass.exist?(user_name)
        raise Error, "Could not find account #{user_name}"
      end
      validate_password(password)

      obj = klass.find(user_name)
      obj.password = password
      if obj.save
        puts "the password of #{user_name} was successfully changed."
      else
        raise "Could not change password of #{klass.name}"
      end
    end

  end
end
