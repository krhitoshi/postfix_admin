require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/cli'

RSpec.describe PostfixAdmin::CLI, "when config file does not exist" do
  before do
    @file = File.join(File.dirname(__FILE__) , 'tmp/postfix_admin.conf')
    CLI.config_file = @file
    FileUtils.rm(@file) if File.exist?(@file)
  end

  it "::config_file#=" do
    expect(CLI.config_file).to eq @file
  end

  it "#new should raise SystemExit and create config_file, permission should be 600" do
    expect do
      $stderr = StringIO.new
      $stdout = StringIO.new
      CLI.new
    ensure
      $stderr = STDERR
      $stdout = STDOUT
    end.to raise_error SystemExit
    expect(File.exist?(@file)).to be true
    expect("%o" % File.stat(@file).mode).to eq "100600"
  end
end

RSpec.describe PostfixAdmin::CLI do
  before do
    CLI.config_file = CLI::DEFAULT_CONFIG_PATH
   @cli = CLI.new
  end

  describe "#show" do
    it "show all domains information by nil domain name" do
      expect { capture(:stdout) { @cli.show(nil) } }.to_not raise_error
    end

    it "show domain information" do
      expect { capture(:stdout) { @cli.show('example.com') } }.to_not raise_error
    end

    it "can use frozen domain name" do
      domain = 'example.com'
      expect { capture(:stdout) { @cli.show(domain.freeze) } }.to_not raise_error
    end

    it "upcase will convert to downcase" do
      expect { capture(:stdout) { @cli.show('ExAmpLe.CoM') } }.to_not raise_error
    end

    it "when unknown domain, raises Error" do
      expect { capture(:stdout) { @cli.show('unknown.example.com') } }.to raise_error Error
    end
  end

  it "#show_domains" do
    expect { capture(:stdout) { @cli.show_domains } }.to_not raise_error
    expect(capture(:stdout) { @cli.show_domains }).to_not match /ALL/
  end

  describe "#show_account_details" do
    it "shows information of an account" do
      expect { capture(:stdout) { @cli.show_account_details('user@example.com') } }.to_not raise_error
      result = capture(:stdout) { @cli.show_account_details('user@example.com') }
      expect(result).to match /Name/
      expect(result).to match /Quota/
    end

    it "raises error when unknown account" do
      expect { capture(:stdout) { @cli.show_account_details('unknown@example.com') } }.to raise_error Error
    end
  end

  describe "#show_summary" do
    it "show summary of all domain" do
      expect { capture(:stdout) { @cli.show_summary } }.to_not raise_error
    end

    it "show summary of domain" do
      expect { capture(:stdout) { @cli.show_summary('example.com') } }.to_not raise_error
    end

    it "upcase will convert to downcase" do
      expect { capture(:stdout) { @cli.show_summary('example.COM') } }.to_not raise_error
    end

    it "when unknown domain, raises Error" do
      expect { capture(:stdout) { @cli.show_summary('unknown.example.com') } }.to raise_error Error
    end
  end

  it "#show_admins" do
    expect { capture(:stdout) { @cli.show_admins } }.to_not raise_error
  end

  it "#show_accounts" do
    expect { capture(:stdout) { @cli.show_accounts('example.com') } }.to_not raise_error
    expect { capture(:stdout) { @cli.show_accounts('unknown.example.com') } }.to raise_error Error
  end

  it "#show_admin_domain" do
    expect { capture(:stdout) { @cli.show_admin_domain('admin@example.com') } }.to_not raise_error
  end

  it "#show_alias" do
    expect { capture(:stdout) { @cli.show_alias('example.com') } }.to_not raise_error
    expect { capture(:stdout) { @cli.show_alias('unknown.example.com') } }.to raise_error Error
  end

  describe "change password" do
    it "#change_admin_password" do
      expect { capture(:stdout) { @cli.change_admin_password('admin@example.com', 'new_password') } }.to_not raise_error
      expect(Admin.find('admin@example.com').password).to eq CRAM_MD5_NEW_PASS
      expect { capture(:stdout) { @cli.change_admin_password('unknown_admin@example.com', 'new_password') } }.to raise_error Error

      expect { capture(:stdout) { @cli.change_admin_password('admin@example.com', '1234') } }.to raise_error ArgumentError
    end

    it "#change_account_password" do
      expect { capture(:stdout) { @cli.change_account_password('user@example.com', 'new_password') } }.to_not raise_error
      expect(Mailbox.find('user@example.com').password).to eq CRAM_MD5_NEW_PASS
      expect { capture(:stdout) { @cli.change_account_password('unknown@example.com', 'new_password') } }.to raise_error Error
      expect { capture(:stdout) { @cli.change_account_password('user@example.com', '1234') } }.to raise_error ArgumentError
    end

    describe "without prefix" do
      before do
        CLI.config_file = File.join(File.dirname(__FILE__) ,
                                    'postfix_admin.conf.without_prefix')
        @cli = CLI.new
      end

      it "#change_admin_password without prefix" do
        expect { capture(:stdout) { @cli.change_admin_password('admin@example.com', 'new_password') } }.to_not raise_error
        expect(Admin.find('admin@example.com').password).to eq CRAM_MD5_NEW_PASS_WITHOUT_PREFIX
        expect { capture(:stdout) { @cli.change_admin_password('unknown_admin@example.com', 'new_password') } }.to raise_error Error

        expect { capture(:stdout) { @cli.change_admin_password('admin@example.com', '1234') } }.to raise_error ArgumentError
      end

      it "#change_account_password" do
        expect { capture(:stdout) { @cli.change_account_password('user@example.com', 'new_password') } }.to_not raise_error
        expect(Mailbox.find('user@example.com').password).to eq CRAM_MD5_NEW_PASS_WITHOUT_PREFIX
        expect { capture(:stdout) { @cli.change_account_password('unknown@example.com', 'new_password') } }.to raise_error Error
        expect { capture(:stdout) { @cli.change_account_password('user@example.com', '1234') } }.to raise_error ArgumentError
      end
    end
  end

  describe "#add_admin" do
    it "can add a new admin" do
      expect { capture(:stdout) { @cli.add_admin('new_admin@example.com', 'password') } }.to_not raise_error
      expect(Admin.exists?('new_admin@example.com')).to be true
    end

    it "can not add exist admin" do
      expect { capture(:stdout) { @cli.add_admin('admin@example.com', 'password') } }.to raise_error Error
    end

    it "does not allow too short password (<5)" do
      expect { capture(:stdout) { @cli.add_admin('admin@example.com', '1234') } }.to raise_error ArgumentError
    end
  end

  describe "#delete_admin" do
    it "can delete an admin" do
      expect { capture(:stdout) { @cli.delete_admin('admin@example.com') } }.to_not raise_error
      expect(Admin.exists?('admin@example.com')).to be false
    end

    it "can delete a super admin" do
      expect { capture(:stdout) { @cli.delete_admin('all@example.com') } }.to_not raise_error
      expect(Admin.exists?('all@example.com')).to be false
    end

    it "can delete an admin whish has multiple domains" do
      capture(:stdout) { @cli.add_admin_domain('admin@example.com', 'example.org') }
      expect { capture(:stdout) { @cli.delete_admin('admin@example.com') } }.to_not raise_error
      expect(Admin.exists?('admin@example.com')).to be false
    end

    it "can not delete unknown admin" do
      expect { capture(:stdout) { @cli.delete_admin('unknown_admin@example.com') } }.to raise_error Error
    end
  end

  it "#add_alias and #delete_alias" do
    expect { capture(:stdout) { @cli.add_alias('user@example.com', 'goto@example.jp') } }.to raise_error Error
    expect { capture(:stdout) { @cli.delete_alias('user@example.com') } }.to raise_error Error
    expect { capture(:stdout) { @cli.delete_alias('unknown@example.com') } }.to raise_error Error

    expect { capture(:stdout) { @cli.add_alias('new_alias@example.com', 'goto@example.jp') } }.to_not raise_error
    expect(Alias.exists?('new_alias@example.com')).to be true

    expect { capture(:stdout) { @cli.delete_alias('new_alias@example.com') } }.to_not raise_error
    expect(Alias.exists?('new_alias@example.com')).to be false
  end

  describe "#add_account" do
    it "can add an account" do
      expect { capture(:stdout) { @cli.add_account('new_user@example.com', 'password') } }.to_not raise_error
      expect(Mailbox.exists?('new_user@example.com')).to be true
      expect(Alias.exists?('new_user@example.com')).to be true
    end

    it "can not add account of unknown domain" do
      expect { capture(:stdout) { @cli.add_account('user@unknown.example.com', 'password') } }.to raise_error Error
    end

    it "does not allow too short password (<5)" do
      expect { capture(:stdout) { @cli.add_account('new_user@example.com', '1234') } }.to raise_error ArgumentError
    end
  end

  describe "#delete_accont" do
    it "can delete an account" do
      expect { capture(:stdout) { @cli.delete_account('user@example.com') } }.to_not raise_error
      expect(Mailbox.exists?('user@example.com')).to be false
      expect(Alias.exists?('user@example.com')).to be false
    end

    it "can not delete unknown account" do
      expect { capture(:stdout) { @cli.delete_account('unknown@example.com') } }.to raise_error Error
    end
  end

  describe "#add_domain" do
    it "can add a new domain" do
      expect { capture(:stdout) { @cli.add_domain('example.net') } }.to_not raise_error
    end

    it "upcase will convert to downcase" do
      expect { capture(:stdout) { @cli.add_domain('ExAmPle.NeT') } }.to_not raise_error
      expect(Domain.exists?('example.net')).to be true
    end

    it "can not add exist domain" do
      expect { capture(:stdout) { @cli.add_domain('example.com') } }.to raise_error Error
      expect { capture(:stdout) { @cli.add_domain('ExAmPle.Com') } }.to raise_error Error
    end
  end

  describe "#edit_domain" do
    it "can update domain limitations" do
      args = { aliases: 40, mailboxes: 40, maxquota: 400, active: false }
      expect { capture(:stdout) { @cli.edit_domain('example.com', args) } }.to_not raise_error
      domain = Domain.find('example.com')
      expect(domain.aliases).to eq 40
      expect(domain.mailboxes).to eq 40
      expect(domain.maxquota).to eq 400
      expect(domain.active).to be false
    end
  end

  describe "#edit_account" do
    it "can update account" do
      args = { quota: 50,
               goto: 'user@example.com,goto@example.jp',
               active: false }
      expect { capture(:stdout) { @cli.edit_account('user@example.com', args) } }.to_not raise_error
      mailbox = Mailbox.find('user@example.com')
      expect(mailbox.quota).to eq 50 * KB_TO_MB
      expect(mailbox.alias.goto).to eq('user@example.com,goto@example.jp')
      expect(mailbox.active).to be(false)
    end

    it "raise error when unknown account" do
      expect { capture(:stdout) { @cli.edit_account('unknown@example.com', {quota: 50}) } }.to raise_error Error
    end
  end

  describe "#edit_admin" do
    it "can update admin" do
      expect { capture(:stdout) { @cli.edit_admin('admin@example.com',
                                                  { super: true, active: false }) } }.not_to raise_error
      admin = Admin.find('admin@example.com')
      expect(admin.super_admin?).to be true
      expect(admin.superadmin).to be true if admin.has_superadmin_column?
      expect(admin.active).to be false
    end

    it "can disable super admin" do
      expect { capture(:stdout) { @cli.edit_admin('all@example.com',
                                                  { super: false }) } }.not_to raise_error
      admin = Admin.find('all@example.com')
      expect(admin.super_admin?).to be false
      expect(admin.superadmin).to be false if admin.has_superadmin_column?
    end
  end

  describe "#delete_domain" do
    it "can delete exist domain" do
      expect { capture(:stdout) { @cli.delete_domain('example.com') } }.to_not raise_error
      expect(Domain.exists?('example.net')).to be false
    end

    it "upcase will convert to downcase" do
      expect { capture(:stdout) { @cli.delete_domain('eXaMplE.cOm') } }.to_not raise_error
      expect(Domain.exists?('example.com')).to be false
    end

    it "can delete related admins, addresses and aliases" do
      capture(:stdout) do
        @cli.add_account('user2@example.com', 'password')

        @cli.add_admin('other_admin@example.com', 'password')
        @cli.add_admin_domain('other_admin@example.com', 'example.com')
      end

      expect { capture(:stdout) { @cli.delete_domain('example.com') } }.to_not raise_error

      # `delete_domain` does not delete a admin user anymore
      expect(Admin.exists?('admin@example.com')).to be true
      expect(Admin.exists?('other_admin@example.com')).to be true

      # aliases should be removed
      expect(Alias.exists?('alias@example.com')).to be false
      expect(Alias.exists?('user@example.com')).to be false
      expect(Alias.exists?('user2@example.com')).to be false

      # mailboxes should be removed
      expect(Mailbox.exists?('user@example.com')).to be false
      expect(Mailbox.exists?('user2@example.com')).to be false
    end
  end

  describe "#dump" do
    it do
      expect { capture(:stdout) { @cli.dump } }.to_not raise_error
    end

    it "print infomation of all domains" do
      result = capture(:stdout) { @cli.dump }
      expect(result).to match /example.com,100,true/
      expect(result).to match /example.org,100,true/
      expect(result).to match /admin@example.com,"{CRAM-MD5}9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740",false,true/
      expect(result).to match /user@example.com,"","{CRAM-MD5}9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740",102400000,"example.com\/user@example.com\/",true/
      expect(result).to match /alias@example.com,"goto@example.jp",true/
      # expect(result).to match /user@example.com,"goto@example.jp",true/
    end
  end
end
