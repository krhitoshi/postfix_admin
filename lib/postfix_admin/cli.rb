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
        # address like argument
        if Admin.exists?(name)
          # admin
          show_admin_details(name, display_password: true)
          puts
          show_admin_domain(name)
        elsif Mailbox.exists?(name)
          # mailbox
          show_account_details(name, display_password: true)
        elsif Alias.exists?(name)
          # alias
          show_alias_details(name)
        else
          raise Error, "Could not find admin/mailbox/alias #{name}"
        end

        return
      end

      show_summary(name)
      puts

      if name
        # domain name
        show_domain_details(name)
      else
        # no argument: show all domains and admins
        show_domain
        puts
        show_admin
      end
    end

    def show_summary(domain_name = nil)
      if domain_name
        show_domain_summary(domain_name)
      else
        show_general_summary
      end
    end

    # Set up a domain
    # Add a domain, add an admin, and grant the admin access to the domain
    def setup_domain(domain_name, password, scheme: nil, rounds: nil)
      admin = "admin@#{domain_name}"
      add_domain(domain_name)
      add_admin(admin, password, scheme: scheme, rounds: rounds)
      add_admin_domain(admin, domain_name)
    end

    def show_account_details(user_name, display_password: false)
      account_check(user_name)
      mailbox    = Mailbox.find(user_name)
      mail_alias = Alias.find(user_name)

      rows = []
      puts_title("Mailbox")
      rows << ["Address", mailbox.username]
      rows << ["Name", mailbox.name]
      rows << ["Password", mailbox.password] if display_password
      rows << ["Quota (MB)", mailbox.quota_mb_str]
      rows << ["Go to", mail_alias.goto]
      rows << ["Active", mailbox.active_str]

      puts_table(rows: rows)
    end

    def show_admin_details(name, display_password: false)
      admin_check(name)
      admin = Admin.find(name)

      rows = []
      puts_title("Admin")
      rows << ["Name", admin.username]
      rows << ["Password", admin.password] if display_password
      rows << ["Domains", admin.super_admin? ? "ALL" : admin.rel_domains.count.to_s]
      rows << ["Role", admin.super_admin? ? "Super Admin" : "Standard Admin"]
      rows << ["Active", admin.active_str]

      puts_table(rows: rows)
    end

    def show_alias_details(name)
      alias_check(name)
      mail_alias = Alias.find(name)

      rows = []
      puts_title("Alias")
      rows << ["Address", mail_alias.address]
      rows << ["Go to", mail_alias.goto]
      rows << ["Active", mail_alias.active_str]

      puts_table(rows: rows)
    end

    def show_domain
      rows = []
      headings = ["No.", "Domain", "Aliases", "Mailboxes","Max Quota (MB)",
                  "Active", "Description"]

      puts_title("Domains")
      if Domain.without_all.empty?
        puts "No domains"
        return
      end

      Domain.without_all.each_with_index do |d, i|
        no = i + 1
        aliases_str = "%4d / %4s" % [d.pure_aliases.count, d.aliases_str]
        mailboxes_str = "%4d / %4s" % [d.rel_mailboxes.count, d.mailboxes_str]
        rows << [no.to_s, d.domain, aliases_str, mailboxes_str,
                 d.maxquota_str, d.active_str, d.description]
      end

      puts_table(headings: headings, rows: rows)
    end

    def add_domain(domain_name, description: nil)
      @base.add_domain(domain_name, description: description)
      puts_registered(domain_name, "a domain")
    end

    def change_admin_password(user_name, password, scheme: nil, rounds: nil)
      change_password(Admin, user_name, password, scheme: scheme, rounds: rounds)
    end

    def change_account_password(user_name, password, scheme: nil, rounds: nil)
      change_password(Mailbox, user_name, password, scheme: scheme, rounds: rounds)
    end

    def edit_admin(admin_name, options)
      admin_check(admin_name)
      admin = Admin.find(admin_name)

      unless options[:super].nil?
        admin.super_admin = options[:super]
      end

      admin.active = options[:active] unless options[:active].nil?
      admin.save!

      puts "successfully updated #{admin_name}"
      show_admin_details(admin_name)
    end

    def edit_domain(domain_name, options)
      domain_check(domain_name)
      domain = Domain.find(domain_name)
      domain.aliases   = options[:aliases]   if options[:aliases]
      domain.mailboxes = options[:mailboxes] if options[:mailboxes]
      domain.maxquota     = options[:maxquota]  if options[:maxquota]
      domain.active       = options[:active] unless options[:active].nil?
      domain.description  = options[:description] if options[:description]
      domain.save!

      puts "successfully updated #{domain_name}"
      show_summary(domain_name)
    end

    def delete_domain(domain_name)
      @base.delete_domain(domain_name)
      puts_deleted(domain_name)
    end

    def show_admin(domain_name = nil)
      admins = domain_name ? Admin.select { |a| a.rel_domains.exists?(domain_name) } : Admin.all
      headings = ["No.", "Admin", "Domains", "Active", "Scheme Prefix"]

      puts_title("Admins")
      if admins.empty?
        puts "No admins"
        return
      end

      rows = []
      admins.each_with_index do |a, i|
        no = i + 1
        domains = a.super_admin? ? 'Super Admin' : a.rel_domains.count
        rows << [no.to_s, a.username, domains.to_s, a.active_str, a.scheme_prefix]
      end

      puts_table(headings: headings, rows: rows)
    end

    def show_address(domain_name)
      domain_check(domain_name)

      rows = []
      mailboxes = Domain.find(domain_name).rel_mailboxes
      headings = ["No.", "Email", "Name", "Quota (MB)", "Active",
                  "Scheme Prefix", "Maildir"]

      puts_title("Addresses")
      if mailboxes.empty?
        puts "No addresses"
        return
      end

      mailboxes.each_with_index do |m, i|
        no = i + 1
        rows << [no.to_s, m.username, m.name, m.quota_mb_str,
                 m.active_str, m.scheme_prefix, m.maildir]
      end

      puts_table(headings: headings, rows: rows)
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
      puts_title("Admin Domains (#{user_name})")
      if admin.rel_domains.empty?
        puts "\nNo domains for #{user_name}"
        return
      end

      rows = []
      admin.rel_domains.each_with_index do |d, i|
        no = i + 1
        rows << [no.to_s, d.domain]
      end
      puts_table(rows: rows, headings: %w[No. Domain])
    end

    def add_admin(user_name, password, super_admin: false,
                  scheme: nil, rounds: nil)
      validate_password(password)

      h_password = hashed_password(password, user_name: user_name,
                                   scheme: scheme, rounds: rounds)
      @base.add_admin(user_name, h_password)

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

    def add_account(address, password, name: nil, scheme: nil, rounds: nil)
      validate_password(password)

      h_password = hashed_password(password, user_name: address,
                                   scheme: scheme, rounds: rounds)
      @base.add_account(address, h_password, name: name)
      puts_registered(address, "an account")
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

      puts "successfully updated #{address}"
      show_account_details(address)
    end

    def edit_alias(address, options)
      alias_check(address)
      mail_alias = Alias.find(address)
      mail_alias.goto = options[:goto] if options[:goto]
      mail_alias.active = options[:active] unless options[:active].nil?
      mail_alias.save or raise "Could not save Alias"

      puts "successfully updated #{address}"
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

    def log(domain: nil, last: nil)
      headings = %w[Timestamp Admin Domain Action Data]
      rows = []

      logs = if domain
               Log.where(domain: domain)
             else
               Log.all
             end

      logs = logs.last(last) if last

      logs.each do |l|
        # TODO: Consider if zone should be included ('%Z').
        time = l.timestamp.strftime("%Y-%m-%d %X")
        rows << [time, l.username, l.domain, l.action, l.data]
      end

      puts_table(headings: headings, rows: rows)
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

    def show_general_summary
      rows = []
      title = "Summary"
      rows << ["Domains", Domain.without_all.count]
      rows << ["Admins", Admin.count]
      rows << ["Mailboxes", Mailbox.count]
      rows << ["Aliases", Alias.pure.count]

      puts_title(title)
      puts_table(rows: rows)
    end

    def show_domain_summary(domain_name)
      domain_name = domain_name.downcase
      domain_check(domain_name)

      rows = []
      domain = Domain.find(domain_name)
      rows << ["Mailboxes", "%4d / %4s" % [domain.rel_mailboxes.count, domain.mailboxes_str]]
      rows << ["Aliases", "%4d / %4s" % [domain.pure_aliases.count, domain.aliases_str]]
      rows << ["Max Quota (MB)", domain.maxquota_str]
      rows << ["Active", domain.active_str]
      rows << ["Description", domain.description]

      puts_title(domain_name)
      puts_table(rows: rows)
    end

    def show_domain_details(domain_name)
      show_admin(domain_name)
      puts
      show_address(domain_name)
      puts
      show_alias(domain_name)
    end

    def show_alias_base(title, addresses)
      rows = []
      puts_title(title)

      if addresses.empty?
        puts "No #{title.downcase}"
        return
      end

      headings = ["No.", "Address", "Active", "Go to"]
      addresses.each_with_index do |a, i|
        no = i + 1
        rows << [no.to_s, a.address, a.active_str, a.goto]
      end

      puts_table(headings: headings, rows: rows)
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

    def puts_table(args)
      puts Terminal::Table.new(args)
    end

    def puts_title(title)
      puts "| #{title} |"
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

    def change_password(klass, user_name, password, scheme: nil, rounds: nil)
      raise Error, "Could not find #{user_name}" unless klass.exists?(user_name)

      validate_password(password)

      obj = klass.find(user_name)
      h_password = hashed_password(password, scheme: scheme, rounds: rounds,
                                   user_name: user_name)

      if obj.update(password: h_password)
        puts "the password of #{user_name} was successfully updated."
      else
        raise "Could not change password of #{klass.name}"
      end
    end

    # The default number of rounds for BLF-CRYPT in `doveadm pw` is 5.
    # However, this method uses 10 rounds by default, similar to
    # the password_hash() function in PHP.
    #
    # https://www.php.net/manual/en/function.password-hash.php
    # <?php
    #   echo password_hash("password", PASSWORD_BCRYPT);
    #
    # $2y$10$qzRgjWZWfH4VsNQGvp/DNObFSaMiZxXJSzgXqOOS/qtF68qIhhwFe
    DEFAULT_BLF_CRYPT_ROUNDS = 10

    # Generate a hashed password
    def hashed_password(password, scheme: nil, rounds: nil, user_name: nil)
      prefix = @base.config[:passwordhash_prefix]
      new_scheme = scheme || @base.config[:scheme]
      new_rounds = if rounds
                     rounds
                   elsif new_scheme == "BLF-CRYPT"
                     DEFAULT_BLF_CRYPT_ROUNDS
                   end
      PostfixAdmin::Doveadm.password(password, new_scheme, rounds: new_rounds,
                                     user_name: user_name, prefix: prefix)
    end
  end
end
