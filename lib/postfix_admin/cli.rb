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

    def show_summary(domain=nil)
      if domain
        unless @base.domain_exist?(domain)
          raise %Q!Could not find domain "#{domain}"!
        end
        puts "[Summary of #{domain}]"
      else
        puts "[Summary]"
      end
      print_line
      unless domain
        puts "Domains   : %4d" % @base.domains.count
        puts "Admins    : %4d" % @base.admins.count
      end

      puts "Mailboxes : %4d" % @base.mailboxes(domain).count
      puts "Aliases   : %4d" % @base.num_total_aliases(domain)
      print_line
    end

    def setup_domain(domain, password)
      admin = "admin@#{domain}"
      add_domain(domain)
      add_admin(admin, password)
      add_admin_domain(admin, domain)
    end

    def show_domain
      puts "\n[Domains]"
      print_line
      puts " No. Domain                Aliases   Mailboxes     Quota (MB)"
      print_line
      @base.domains.each_with_index do |domain, i|
        puts "%4d %-20s %3d /%3d   %3d /%3d %10d" % [i+1, domain.domain, @base.num_total_aliases(domain.domain), domain.aliases, @base.mailboxes(domain.domain).size, domain.mailboxes, domain.maxquota]
      end
      print_line
    end

    def add_domain(domain)
      if @base.add_domain(domain)
        puts %Q!"#{domain}" was successfully registered.!
      end
    end

    def delete_domain(domain)
      if @base.delete_domain(domain)
        puts %Q!"#{domain}" was successfully deleted.!
      end
    end

    def admin_exist?(admin)
      @base.admin_exist?(admin)
    end

    def alias_exist?(address)
      @base.alias_exist?(address)
    end

    def show_admin
      admins = @base.admins
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
      mailboxes = @base.mailboxes(domain)
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
      aliases = @base.aliases(domain).find_all do |mail_alias|
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
      domain_admins = @base.admin_domains(user_name)
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
      if @base.add_admin(user_name, password)
        puts %Q!"#{user_name}" was successfully registered as an admin.!
      end
    end

    def add_admin_domain(user_name, domain)
      if @base.add_admin_domain(user_name, domain)
        puts %Q!"#{domain}" was successfully registered as a domain of #{user_name}.!
      end
    end

    def add_account(address, password)
      validate_password(password)
      if @base.add_account(address, password)
        puts %Q!"#{address}" was successfully registered as an account.!
      end
    end

    def add_alias(address, goto)
      if @base.add_alias(address, goto)
        puts %Q!"#{address}: #{goto}" was successfully registered as an alias.!
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

    def validate_password(password)
      if password.size < MIN_NUM_PASSWORD_CHARACTER
        raise "Password is too short. It should be larger than #{MIN_NUM_PASSWORD_CHARACTER}"
      end
    end

  end
end
