require 'yaml'
require 'postfix_admin'

class PostfixAdmin
  class CLI
    CONFIG_FILE = '~/.postfix_admin.conf'
    MIN_NUM_PASSWORD_CHARACTER = 5

    def initialize
      @config = load_config
      @admin = PostfixAdmin::Base.new(@config)
    end

    def show_summary
      puts "[Summary]"
      print_line
      puts "Domains   : %4d" % @admin.domains.count
      puts "Admins    : %4d" % @admin.admins.count
      puts "Mailboxes : %4d" % @admin.mailboxes.count
      puts "Aliases   : %4d" % @admin.num_total_aliases
      print_line
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

    def admin_exist?(admin)
      @admin.admin_exist?(admin)
    end

    def show_admin
      admins = @admin.admins
      if admins.count == 0
        puts "No admin in database"
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
        puts "No address in #{domain}"
        return
      end

      puts "\n[Accounts]"
      print_line
      puts " No. Email                           Password                Quota (MB)"
      print_line
      mailboxes.each_with_index do |mailbox, i|
        puts "%4d %-30s  %-20s %10.1f" % [i+1, mailbox.username, mailbox.password, mailbox.quota.to_f/1024000.0]
      end
      print_line
    end

    def show_domain_aliases(domain)
      aliases = @admin.aliases(domain)
      if aliases.count == 0
        puts "No aliases in #{domain}"
        return
      end
      puts "\n[Aliases]"
      print_line
      puts " No. Address                        Go to"
      print_line
      aliases.each_with_index do |mail_alias, i|
        if mail_alias.address != mail_alias.goto
          puts "%4d %-30s %s" % [i+1, mail_alias.address, mail_alias.goto]
        end
      end
      print_line
    end

    def show_admin_domain(user_name)
      domain_admins = @admin.admin_domains(user_name)
      if domain_admins.count == 0
        puts "No domain in database"
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

    def add_domain(domain)
      @admin.add_domain(domain)
    end

    def add_admin(user_name, password)
      validate_password(password)
      @admin.add_admin(user_name, password)
    end

    def add_admin_domain(user_name, domain)
      @admin.add_admin_domain(user_name, domain)
    end

    def add_account(address, password)
      validate_password(password)
      @admin.add_account(address, password)
    end

    def add_alias(address, goto)
      @admin.add_alias(address, goto)
    end

    def delete_domain(domain)
      @admin.delete_domain(domain)
    end

    def delete_admin(user_name)
      @admin.delete_admin(user_name)
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
        raise "Error: Password is too short. It should be larger than #{MIN_NUM_PASSWORD_CHARACTER}"
      end
    end
  end
end
