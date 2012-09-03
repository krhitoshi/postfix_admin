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
    def show_domain
      print_line
      puts " No.   domain             alias mail quota"
      print_line
      @admin.domains.each_with_index do |domain, i|
        printf("%4d %-20s %4d %4d %4d\n", i+1, domain.domain, domain.aliases, domain.mailboxes, domain.maxquota)
      end
      print_line
    end
    def show_admin
      admins = @admin.admins
      if admins.count == 0
        puts "No admin in database\n"
        return
      end
      print_line
      puts " No.   username           password"
      print_line
      admins.each_with_index do |admin, i|
        printf("%4d %-20s %10s\n", i+1, admin.username, admin.password)
      end
      print_line
    end
    def show_domain_account(domain)
      mailboxes = @admin.mailboxes(domain)
      if mailboxes.count == 0
        puts "No address in #{domain}\n"
        return
      end
      print_line
      puts " No.   address             password  quota(M) maildir"
      print_line
      mailboxes.each_with_index do |mailbox, i|
        printf("%4d %-20s %10s %7.1f  %-30s\n", i+1, mailbox.username, mailbox.password, mailbox.quota.to_f/1024000.0, mailbox.maildir)
      end
      print_line
    end
    def show_admin_domain(user_name)
      domain_admins = @admin.admin_domains(user_name)
      if domain_admins.count == 0
        puts "No domain in database\n"
        return
      end
      print_line
      puts " No.   domain"
      print_line
      domain_admins.each_with_index do |domain_admin, i|
        printf("%4d %-20s\n", i+1, domain_admin.domain)
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

    private

    def load_config
      unless File.exist?(config_file)
        create_config
        puts "configure file: #{config_file} was generated.\nPlease execute after edit it."
        exit
      end
      open(config_file) do |f|
        YAML.load(f.read)
      end
    end
    def create_config
      open(config_file, 'w') do |f|
        f.write PostfixAdmin::Base::DEFAULT_CONFIG.to_yaml
      end
      File.chmod(0600, config_file)
    end
    def config_file
      File.expand_path(CONFIG_FILE)
    end
    def print_line
      puts "-"*85
    end
    def validate_password(password)
      if password.size < MIN_NUM_PASSWORD_CHARACTER
        raise "Error: Password is too short. It should be larger than #{MIN_NUM_PASSWORD_CHARACTER}"
      end
    end
  end
end
