require 'yaml'
require 'postfix_admin'

module PostfixAdmin
  class CLI
    @config_file = '~/.postfix_admin.conf'
    MIN_NUM_PASSWORD_CHARACTER = 5

    def initialize
      @config = load_config
      @base = PostfixAdmin::Base.new(@config)
    end

    def self.config_file
      @config_file
    end

    def self.config_file=(value)
      @config_file = value
    end

    def show(domain)
      domain = domain.downcase if domain
      show_summary(domain)

      if domain
        show_admin(domain)
        show_address(domain)
        show_alias(domain)
      else
        show_domain
        show_admin
      end
    end

    def show_summary(domain_name=nil)
      title = "Summary"
      if domain_name
        domain_name = domain_name.downcase
        domain_check(domain_name)
        title = "Summary of #{domain_name}"
      end

      report(title) do
        if domain_name
          domain = Domain.find(domain_name)
          puts "Mailboxes : %4d / %4s"    % [domain.mailboxes.count, max_str(domain.maxmailboxes)]
          puts "Aliases   : %4d / %4s"    % [domain.num_total_aliases, max_str(domain.maxaliases)]
          puts "Max Quota : %4d MB" % domain.maxquota
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
      index = " No. Domain                          Aliases   Mailboxes     Quota (MB)"
      report('Domains', index) do
        if Domain.all_without_special_domain.empty?
          puts " No domains"
        else
          Domain.all_without_special_domain.each_with_index do |d, i|
            puts "%4d %-30s %3d /%3s   %3d /%3s %10d" %
              [i+1, d.domain_name, d.num_total_aliases, max_str(d.maxaliases),
               d.mailboxes.count, max_str(d.maxmailboxes), d.maxquota]
          end
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

    def edit_domain(domain_name, options)
      domain_check(domain_name)
      domain = Domain.find(domain_name)
      domain.maxaliases   = options[:aliases]   if options[:aliases]
      domain.maxmailboxes = options[:mailboxes] if options[:mailboxes]
      domain.maxquota     = options[:maxquota]  if options[:maxquota]
      domain.save or raise "Could not save Domain"

      puts "Successfully updated #{domain_name}"
      show_summary(domain_name)
    end

    def delete_domain(domain)
      if @base.delete_domain(domain)
        puts_deleted(domain)
      end
    end

    def show_admin(domain=nil)
      admins = domain ? Admin.select{|a| a.has_domain?(domain)} : Admin.all
      index = " No. Admin                                        Domains Password"
      report("Admins", index) do
        if admins.empty?
          puts " No admins"
        else
          admins.each_with_index do |a, i|
            domains = a.super_admin? ? 'Super admin' : a.domains.count
            puts "%4d %-40s %11s %s" % [i+1, a.username, domains, a.password]
          end
        end
      end

    end

    def show_address(domain)
      domain_check(domain)

      mailboxes = Domain.find(domain).mailboxes
      index = " No. Email                                     Quota (MB) Password        Maildir"
      report("Addresses", index) do
        if mailboxes.empty?
          puts " No addresses"
        else
          mailboxes.each_with_index do |m, i|
            quota = m.quota.to_f/ KB_TO_MB.to_f
            puts "%4d %-40s  %10d %-15s %s" % [i+1, m.username, quota, m.password, m.maildir]
          end
        end
      end

    end

    def show_alias(domain)
      domain_check(domain)

      forwards, aliases = Domain.find(domain).aliases.partition{|a| a.mailbox?}

      forwards.delete_if do |f|
        f.address == f.goto
      end

      index = " No. Address                                  Go to"
      [["Forwards", forwards], ["Aliases", aliases]].each do |title, list|
        report(title, index) do
          if list.empty?
            puts " No #{title.downcase}"
          else
            list.each_with_index do |a, i|
              puts "%4d %-40s %s" % [i+1, a.address, a.goto]
            end
          end
        end
      end

    end

    def show_admin_domain(user_name)
      admin = Admin.find(user_name)
      if admin.domains.empty?
        puts "\nNo domain in database"
        return
      end
      report("Domains (#{user_name})", " No. Domain") do
        admin.domains.each_with_index do |d, i|
          puts "%4d %-30s" % [i+1, d.domain_name]
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

    def delete_admin_domain(user_name, domain_name)
      if @base.delete_admin_domain(user_name, domain_name)
        puts "#{domain_name} was successfully deleted from #{user_name}"
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

    def edit_account(address, options)
      mailbox_check(address)
      mailbox = Mailbox.find(address)
      mailbox.quota = options[:quota] * KB_TO_MB if options[:quota]
      mailbox.save or raise "Could not save Mailbox"

      puts "Successfully updated #{address}"
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
      config_file = File.expand_path(CLI.config_file)
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
        f.write Base::DEFAULT_CONFIG.to_yaml
      end
      File.chmod(0600, config_file)
    end

    def print_line
      puts "-"*120
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
      klass_check(Domain, domain_name)
    end

    def mailbox_check(address)
      klass_check(Mailbox, address)
    end

    def klass_check(klass, name)
      object_name = klass.name.gsub(/PostfixAdmin::/, '').downcase
      raise Error, %Q!Could not find #{object_name} "#{name}"! unless klass.exist?(name)
    end

    def validate_password(password)
      if password.size < MIN_NUM_PASSWORD_CHARACTER
        raise ArgumentError, "Password is too short. It should be larger than #{MIN_NUM_PASSWORD_CHARACTER}"
      end
    end

    def change_password(klass, user_name, password)
      unless klass.exist?(user_name)
        raise Error, "Could not find #{user_name}"
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

    def max_str(value)
      case value
      when 0
        '--'
      when -1
        '0'
      else
        value.to_s
      end
    end

  end
end
