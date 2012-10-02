require 'yaml'
require 'postfix_admin'

module PostfixAdmin
  class CLI
    CONFIG_FILE = '~/.postfix_admin.conf'
    MIN_NUM_PASSWORD_CHARACTER = 5

    def initialize
      @config = load_config
      @admin = PostfixAdmin::Base.new(@config)
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

    def show_summary(domain=nil)
      if domain
        unless @admin.domain_exist?(domain)
          raise %Q!Could not find domain "#{domain}"!
        end
        puts "[Summary of #{domain}]"
      else
        puts "[Summary]"
      end
      print_line
      unless domain
        puts "Domains   : %4d" % @admin.domains.count
        puts "Admins    : %4d" % @admin.admins.count
      end

      puts "Mailboxes : %4d" % @admin.mailboxes(domain).count
      puts "Aliases   : %4d" % @admin.num_total_aliases(domain)
      print_line
    end

    def setup_domain(domain, password)
      if domain && password
        admin = "admin@#{domain}"
        add_domain(domain)
        add_admin(admin, password)
        add_admin_domain(admin, domain)
      else
        exit_with_usage('setup', 'example.com password')
      end
    end

    def show_domain
      puts "\n[Domains]"
      print_line
      puts " No. Domain                Aliases   Mailboxes     Quota (MB)"
      print_line
      @admin.domains.each_with_index do |domain, i|
        puts "%4d %-20s %3d /%3d   %3d /%3d %10d" % [i+1, domain.domain, @admin.num_total_aliases(domain.domain), domain.aliases, @admin.mailboxes(domain.domain).size, domain.mailboxes, domain.maxquota]
      end
      print_line
    end

    def add_domain(domain)
      if domain
        if @admin.add_domain(domain)
          puts %Q!"#{domain}" is successfully registered.!
        end
      else
        exit_with_usage('add_domain', 'example.com')
      end
    end

    def delete_domain(domain)
      if domain
        if @admin.delete_domain(domain)
          puts %Q!"#{domain}" is successfully deleted.!
        end
      else
        exit_with_usage('delete_domain', 'example.com')
      end
    end

    def admin_exist?(admin)
      @admin.admin_exist?(admin)
    end

    def alias_exist?(address)
      @admin.alias_exist?(address)
    end

    def show_admin
      admins = @admin.admins
      if admins.count == 0
        puts "\nNo admin in database"
        return
      end
      puts "\n[Admins]"
      print_line
      puts " No. Admin                              Domains Password"
      print_line
      admins.each_with_index do |admin, i|
        domains = if admin.domains.find{ |domain| domain.domain == 'ALL' }
                       'Super admin'
                     else
                       admin.domains.count
                     end
        puts "%4d %-30s %11s %s" % [i+1, admin.username, domains, admin.password]
      end
      print_line
    end

    def show_domain_account(domain)
      mailboxes = @admin.mailboxes(domain)
      if mailboxes.count == 0
        puts "\nNo address in #{domain}"
        return
      end

      puts "\n[Accounts]"
      print_line
      puts " No. Email                           Quota (MB) Password"
      print_line
      mailboxes.each_with_index do |mailbox, i|
        quota = mailbox.quota.to_f/1024000.0
        puts "%4d %-30s  %10.1f %s" % [i+1, mailbox.username, quota, mailbox.password]
      end
      print_line
    end

    def show_domain_aliases(domain)
      aliases = @admin.aliases(domain).find_all do |mail_alias|
        mail_alias.address != mail_alias.goto
      end

      if aliases.count == 0
        puts "\nNo aliases in #{domain}"
        return
      end
      puts "\n[Aliases]"
      print_line
      puts " No. Address                        Go to"
      print_line
      aliases.each_with_index do |mail_alias, i|
        puts "%4d %-30s %s" % [i+1, mail_alias.address, mail_alias.goto]
      end
      print_line
    end

    def show_admin_domain(user_name)
      domain_admins = @admin.admin_domains(user_name)
      if domain_admins.count == 0
        puts "\nNo domain in database"
        return
      end
      puts "\n[Domains (#{user_name})]"
      print_line
      puts " No. Domain"
      print_line
      domain_admins.each_with_index do |domain_admin, i|
        puts "%4d %-20s" % [i+1, domain_admin.domain]
      end
      print_line
    end

    def add_admin(user_name, password)
      validate_password(password)
      @admin.add_admin(user_name, password)
    end

    def add_admin_domain(user_name, domain)
      @admin.add_admin_domain(user_name, domain)
    end

    def add_account(address, password)
      if address && password
        validate_password(password)
        if @admin.add_account(address, password)
          puts %Q!"#{address}" is successfully registered.!
        end
      else
        exit_with_usage('add_account', 'user@example.com password')
      end
    end

    def add_alias(address, goto)
      @admin.add_alias(address, goto)
    end

    def delete_alias(address)
      @admin.delete_alias(address)
    end

    def delete_admin(user_name)
      if user_name
        if @admin.delete_admin(user_name)
          puts %Q!"#{user_name}" is successfully deleted.!
        end
      else
        exit_with_usage('delete_admin', 'admin@example.com')
      end
    end

    def delete_account(address)
      if address
        if @admin.delete_account(address)
          puts %Q!"#{address}" is successfully deleted.!
        end
      else
        exit_with_usage('delete_account', 'user@example.com')
      end
    end

    private

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

    def validate_password(password)
      if password.size < MIN_NUM_PASSWORD_CHARACTER
        raise "Password is too short. It should be larger than #{MIN_NUM_PASSWORD_CHARACTER}"
      end
    end

    private

    def exit_with_usage(subcommand, args)
      puts "Usage: postfix_admin #{subcommand} #{args}"
      exit
    end
  end
end
