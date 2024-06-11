require 'yaml'
require 'postfix_admin'
require 'postfix_admin/doveadm'
require 'terminal-table'

module PostfixAdmin
  class CLI
    DEFAULT_CONFIG_PATH = '~/.postfix_admin.conf'
    @config_file = DEFAULT_CONFIG_PATH
    MIN_NUM_PASSWORD_CHARACTER = 5

    def initialize
      @config = load_config
      @base = Base.new(@config)
    end

    def self.config_file
      @config_file
    end

    def self.config_file=(value)
      @config_file = value
    end

    def db_setup
      @base.db_setup
    end

    def show(name)
      name = name.downcase if name

      if name =~ /@/
        if Admin.exists?(name)
          show_admin_details(name)
        end

        if Mailbox.exists?(name)
          show_account_details(name)
        elsif Alias.exists?(name)
          show_alias_details(name)
        end

        return
      end

      show_summary(name)
      puts

      if name
        show_domain_details(name)
      else
        show_domain
        puts
        show_admin
      end
    end

    def show_summary(domain_name = nil)
      title = "Summary"
      if domain_name
        domain_name = domain_name.downcase
        domain_check(domain_name)
      end

      rows = []
      if domain_name
        puts "| #{domain_name} |"
        domain = Domain.find(domain_name)
        rows << ["Mailboxes", "%4d / %4s" % [domain.rel_mailboxes.count, max_str(domain.mailboxes)]]
        rows << ["Aliases", "%4d / %4s" % [domain.pure_aliases.count, max_str(domain.aliases)]]
        rows << ["Max Quota", "%d MB" % domain.maxquota]
        rows << ["Active", domain.active_str]
      else
        puts "| Summary |"
        rows << ["Domains", Domain.without_all.count]
        rows << ["Admins", Admin.count]
        rows << ["Mailboxes", Mailbox.count]
        rows << ["Aliases", Alias.pure.count]
      end

      puts Terminal::Table.new(rows: rows)
    end

    def setup_domain(domain_name, password)
      admin = "admin@#{domain_name}"
      add_domain(domain_name)
      add_admin(admin, password)
      add_admin_domain(admin, domain_name)
    end

    def show_account_details(user_name)
      account_check(user_name)
      mailbox    = Mailbox.find(user_name)
      mail_alias = Alias.find(user_name)

      report("Mailbox") do
        puts "Address  : %s" % mailbox.username
        puts "Name     : %s" % mailbox.name
        puts "Password : %s" % mailbox.password
        puts "Quota    : %d MB" % max_str(mailbox.quota / KB_TO_MB)
        puts "Go to    : %s" % mail_alias.goto
        puts "Active   : %s" % mailbox.active_str
      end
    end

    def show_admin_details(name)
      admin_check(name)
      admin = Admin.find(name)

      report("Admin") do
        puts "Name     : %s" % admin.username
        puts "Password : %s" % admin.password
        puts "Domains  : %s" % (admin.super_admin? ? "ALL" : admin.rel_domains.count)
        puts "Role     : %s" % (admin.super_admin? ? "Super admin" : "Admin")
        puts "Active   : %s" % admin.active_str
      end
    end

    def show_alias_details(name)
      alias_check(name)
      mail_alias = Alias.find(name)
      report("Alias") do
        puts "Address  : %s" % mail_alias.address
        puts "Go to    : %s" % mail_alias.goto
        puts "Active   : %s" % mail_alias.active_str
      end
    end

    def show_domain
      rows = []
      heddings = ["No.", "Domain", "Aliases", "Mailboxes","Quota (MB)", "Active"]
      index = " No. Domain                          Aliases   Mailboxes     Quota (MB)  Active"

      puts "| Domains |"
      if Domain.without_all.empty?
        puts "No domains"
        return
      end

      Domain.without_all.each_with_index do |d, i|
        no = i + 1
        aliases_str = "%3d /%3s" % [d.pure_aliases.count, max_str(d.aliases)]
        mailboxes_str = "%3d /%3s" % [d.rel_mailboxes.count, max_str(d.mailboxes)]
        rows << [no.to_s, d.domain, aliases_str, mailboxes_str,
                 max_str(d.maxquota), d.active_str]
      end

      puts Terminal::Table.new(headings: heddings, rows: rows)
    end

    def add_domain(domain_name)
      @base.add_domain(domain_name)
      puts_registered(domain_name, "a domain")
    end

    def change_admin_password(user_name, password)
      change_password(Admin, user_name, password)
    end

    def change_account_password(user_name, password)
      change_password(Mailbox, user_name, password)
    end

    def edit_admin(admin_name, options)
      admin_check(admin_name)
      admin = Admin.find(admin_name)

      unless options[:super].nil?
        admin.super_admin = options[:super]
      end

      admin.active = options[:active] unless options[:active].nil?
      admin.save!

      puts "Successfully updated #{admin_name}"
      show_admin_details(admin_name)
    end

    def edit_domain(domain_name, options)
      domain_check(domain_name)
      domain = Domain.find(domain_name)
      domain.aliases   = options[:aliases]   if options[:aliases]
      domain.mailboxes = options[:mailboxes] if options[:mailboxes]
      domain.maxquota     = options[:maxquota]  if options[:maxquota]
      domain.active       = options[:active] unless options[:active].nil?
      domain.save!

      puts "Successfully updated #{domain_name}"
      show_summary(domain_name)
    end

    def delete_domain(domain_name)
      @base.delete_domain(domain_name)
      puts_deleted(domain_name)
    end

    def show_admin(domain_name = nil)
      admins = domain_name ? Admin.select { |a| a.rel_domains.exists?(domain_name) } : Admin.all
      headings = %w[No. Admin Domains Active]

      puts "| Admins |"
      if admins.empty?
        puts "No admins"
        return
      end

      rows = []
      admins.each_with_index do |a, i|
        no = i + 1
        domains = a.super_admin? ? 'Super admin' : a.rel_domains.count
        rows << [no.to_s, a.username, domains.to_s, a.active_str]
      end

      puts Terminal::Table.new(headings: headings, rows: rows)
    end

    def show_address(domain_name)
      domain_check(domain_name)

      rows = []
      mailboxes = Domain.find(domain_name).rel_mailboxes
      headings = ["No.", "Email", "Name", "Quota (MB)", "Active", "Maildir"]

      puts "| Addresses |"
      if mailboxes.empty?
        puts "No addresses"
        return
      end

      mailboxes.each_with_index do |m, i|
        no = i + 1
        quota = m.quota.to_f/ KB_TO_MB.to_f
        rows << [no.to_s, m.username, m.name, max_str(quota.to_i),
                 m.active_str, m.maildir]
      end

      puts Terminal::Table.new(headings: headings, rows: rows)
    end

    def show_alias(domain_name)
      domain_check(domain_name)

      forwards, aliases = Domain.find(domain_name).rel_aliases.partition { |a| a.mailbox? }

      forwards.delete_if do |f|
        f.address == f.goto
      end

      show_alias_base("Forwards", forwards)
      puts
      show_alias_base("Aliases",  aliases)
    end

    def show_admin_domain(user_name)
      admin = Admin.find(user_name)
      if admin.rel_domains.empty?
        puts "\nNo domain in database"
        return
      end

      report("Domains (#{user_name})", " No. Domain") do
        admin.rel_domains.each_with_index do |d, i|
          puts "%4d %-30s" % [i + 1, d.domain]
        end
      end
    end

    def add_admin(user_name, password, super_admin = false, scheme = nil)
      validate_password(password)

      @base.add_admin(user_name, hashed_password(password, scheme))
      if super_admin
        Admin.find(user_name).super_admin = true
        puts_registered(user_name, "a super admin")
      else
        puts_registered(user_name, "an admin")
      end
    end

    def add_admin_domain(user_name, domain_name)
      @base.add_admin_domain(user_name, domain_name)
      puts_registered(domain_name, "a domain of #{user_name}")
    end

    def delete_admin_domain(user_name, domain_name)
      @base.delete_admin_domain(user_name, domain_name)
      puts "#{domain_name} was successfully deleted from #{user_name}"
    end

    def add_account(address, password, scheme = nil, name = nil)
      validate_password(password)

      @base.add_account(address, hashed_password(password, scheme), name: name)
      puts_registered(address, "an account")
      show_account_details(address)
    end

    def add_alias(address, goto)
      @base.add_alias(address, goto)
      puts_registered("#{address}: #{goto}", "an alias")
    end

    def edit_account(address, options)
      mailbox_check(address)
      mailbox = Mailbox.find(address)
      mailbox.name = options[:name] if options[:name]
      mailbox.quota = options[:quota] * KB_TO_MB if options[:quota]
      mailbox.active = options[:active] unless options[:active].nil?
      mailbox.save!

      if options[:goto]
        mail_alias = Alias.find(address)
        mail_alias.goto = options[:goto]
        mail_alias.save!
      end

      puts "Successfully updated #{address}"
      show_account_details(address)
    end

    def edit_alias(address, options)
      alias_check(address)
      mail_alias = Alias.find(address)
      mail_alias.goto = options[:goto] if options[:goto]
      mail_alias.active = options[:active] unless options[:active].nil?
      mail_alias.save or raise "Could not save Alias"

      puts "Successfully updated #{address}"
      show_alias_details(address)
    end

    def delete_alias(address)
      @base.delete_alias(address)
      puts_deleted(address)
    end

    def delete_admin(user_name)
      @base.delete_admin(user_name)
      puts_deleted(user_name)
    end

    def delete_account(address)
      @base.delete_account(address)
      puts_deleted(address)
    end

    def log(domain: nil)
      headings = %w[Timestamp Admin Domain Action Data]
      rows = []

      logs = if domain
               Log.where(domain: domain)
             else
               Log.all
             end

      logs.each do |l|
        time = l.timestamp.strftime("%Y-%m-%d %X %Z")
        rows << [time, l.username, l.domain, l.action, l.data]
      end
      table = Terminal::Table.new(headings: headings, rows: rows)
      puts table
    end

    def dump
      puts "Admins"
      puts "User Name,Password,Super Admin,Active"
      Admin.all.each do |a|
        puts [a.username, %Q!"#{a.password}"!, a.super_admin?, a.active].join(',')
      end
      puts
      puts "Domains"
      puts "Domain Name,Max Quota,Active"
      Domain.without_all.each do |d|
        puts [d.domain, d.maxquota, d.active].join(',')
      end
      puts
      puts "Mailboxes"
      puts "User Name,Name,Password,Quota,Maildir,Active"
      Mailbox.all.each do |m|
        puts [m.username, %Q!"#{m.name}"!, %Q!"#{m.password}"!, m.quota, %Q!"#{m.maildir}"!, m.active].join(',')
      end
      puts
      puts "Aliases"
      puts "Address,Go to,Active"
      Alias.all.select { |a| !a.mailbox? }.each do |a|
        puts [a.address, %Q!"#{a.goto}"!, a.active].join(',')
      end
      puts
      puts "Forwards"
      puts "Address,Go to,Active"
      Alias.all.select { |a| a.mailbox? && a.goto != a.address }.each do |a|
        puts [a.address, %Q!"#{a.goto}"!, a.active].join(',')
      end
    end

    private

    def show_domain_details(domain_name)
      show_admin(domain_name)
      puts
      show_address(domain_name)
      puts
      show_alias(domain_name)
    end

    def show_alias_base(title, addresses)
      rows = []
      puts "| #{title} |"

      if addresses.empty?
        puts "No #{title.downcase}"
        return
      end

      headings = ["No.", "Address", "Active", "Go to"]
      addresses.each_with_index do |a, i|
        no = i + 1
        rows << [no.to_s, a.address, a.active_str, a.goto]
      end

      puts Terminal::Table.new(headings: headings, rows: rows)
    end

    def puts_registered(name, as_str)
      puts %Q!"#{name}" was successfully registered as #{as_str}.!
    end

    def puts_deleted(name)
      puts %Q!"#{name}" was successfully deleted.!
    end

    def config_file
      File.expand_path(CLI.config_file)
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

    def create_config(file)
      open(file, 'w') do |f|
        f.write Base::DEFAULT_CONFIG.to_yaml
      end
      File.chmod(0600, file)
    end

    def print_line
      puts "-"*120
    end

    def report(title, index = nil)
      puts "\n[#{title}]"
      print_line if index
      puts index if index
      print_line
      yield
      print_line
    end

    def account_check(user_name)
      unless Mailbox.exists?(user_name) && Alias.exists?(user_name)
        raise Error, %Q!Could not find account "#{user_name}"!
      end
    end

    def domain_check(domain_name)
      klass_check(Domain, domain_name)
    end

    def mailbox_check(address)
      klass_check(Mailbox, address)
    end

    def alias_check(address)
      klass_check(Alias, address)
    end

    def admin_check(user_name)
      klass_check(Admin, user_name)
    end

    def klass_check(klass, name)
      object_name = klass.name.gsub(/PostfixAdmin::/, '').downcase
      raise Error, %Q!Could not find #{object_name} "#{name}"! unless klass.exists?(name)
    end

    def validate_password(password)
      if password.size < MIN_NUM_PASSWORD_CHARACTER
        raise ArgumentError, "Password is too short. It should be larger than #{MIN_NUM_PASSWORD_CHARACTER}"
      end
    end

    def change_password(klass, user_name, password)
      raise Error, "Could not find #{user_name}" unless klass.exists?(user_name)

      validate_password(password)

      obj = klass.find(user_name)

      if obj.update(password: hashed_password(password))
        puts "the password of #{user_name} was successfully changed."
      else
        raise "Could not change password of #{klass.name}"
      end
    end

    #  0: unlimited
    # -1: disabled
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

    def hashed_password(password, in_scheme = nil)
      prefix = @base.config[:passwordhash_prefix]
      scheme = in_scheme || @base.config[:scheme]
      puts "scheme: #{scheme}"
      PostfixAdmin::Doveadm.password(password, scheme, prefix)
    end
  end
end
