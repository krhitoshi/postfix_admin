require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/runner'

RSpec.describe PostfixAdmin::Runner do
  before do
    db_initialize
  end

  it "version" do
    expect(capture(:stdout) { Runner.start(["version"]) }).to match /postfix_admin \d+\.\d+\.\d/
  end

  it "summary" do
    expect(capture(:stdout) { Runner.start(["summary"]) }).to match /\[Summary\]/
    expect(capture(:stdout) { Runner.start(["summary", "example.com"]) }).to match /\[Summary of example.com\]/
  end

  it "schemes" do
    expect(capture(:stdout) { Runner.start(["schemes"]) }).to match /CLEARTEXT/
  end

  describe "show" do
    it "shows information of example.com" do
      expect(capture(:stdout) { Runner.start(["show"]) }).to match \
        /example.com\s+1\s+\/\s+30\s+1\s+\/\s+30\s+100/
    end

    it "shows information of admin@example.com" do
      expect(capture(:stdout) { Runner.start(["show"]) }).to match \
        /admin@example.com\s+1\s+Active/
    end

    it "show the detail of example.com" do
      expect(capture(:stdout) { Runner.start(["show", "example.com"]) }).to match /user@example.com\s+100\s+Active/
    end

    it "when no admins, no aliases and no addresses" do
      Admin.find('all@example.com').super_admin = false
      out = capture(:stdout) { Runner.start(["show", "example.org"]) }
      expect(out).to match /No admins/
      expect(out).to match /No addresses/
      expect(out).to match /No aliases/
    end

    it "shows information of an admin" do
      expect(capture(:stdout) {  Runner.start(["show", "admin@example.com"]) }).to match /admin@example.com/
    end

    it "shows information of an account" do
      expect(capture(:stdout) {  Runner.start(["show", "user@example.com"]) }).to match /user@example.com/
    end

    it "shows information of an alias" do
      expect(capture(:stdout) {  Runner.start(["show", "alias@example.com"]) }).to match /alias@example.com/
    end

    it "when no domains" do
      expect(capture(:stdout) { Runner.start(['delete_domain', 'example.com']) }).to match EX_DELETED
      expect(capture(:stdout) { Runner.start(['delete_domain', 'example.org']) }).to match EX_DELETED
      expect(capture(:stdout) { Runner.start(["show"]) }).to match /No domains/
    end
  end

  it "setup" do
    expect(capture(:stdout) { Runner.start(['setup', 'example.net', 'password']) }).to match EX_REGISTERED
    expect(capture(:stdout) { Runner.start(['delete_domain', 'example.net']) }).to match EX_DELETED
  end

  describe "admin_passwd" do
    it "can change password of an admin" do
      expect(capture(:stdout) { Runner.start(['admin_passwd', 'admin@example.com', 'new_password']) }).to match /successfully changed/
    end

    it "can not use too short password (< 5)" do
      expect(exit_capture { Runner.start(['admin_passwd', 'admin@example.com', '124']) }).to match /too short/
    end

    it "can not use for unknown admin" do
      expect(exit_capture { Runner.start(['admin_passwd', 'unknown@example.com', 'new_password']) }).to match /Could not find/
    end
  end

  describe "account_passwd" do
    it "can change password of an account" do
      expect(capture(:stdout) { Runner.start(['account_passwd', 'user@example.com', 'new_password']) }).to match /successfully changed/
      expect(Mailbox.find('user@example.com').password).to eq CRAM_MD5_NEW_PASS
    end

    it "can not use too short password (< 5)" do
      expect(exit_capture { Runner.start(['account_passwd', 'user@example.com', '1234']) }).to match /too short/
    end

    it "can not use for unknown account" do
      expect(exit_capture { Runner.start(['account_passwd', 'unknown@example.com', 'new_password']) }).to match /Could not find/
    end
  end

  describe "add_alias and delete_alias" do
    it "can add and delete an new alias." do
      expect(capture(:stdout) { Runner.start(['add_alias', 'new_alias@example.com', 'goto@example.jp']) }).to match EX_REGISTERED
      expect(capture(:stdout) { Runner.start(['delete_alias', 'new_alias@example.com']) }).to match EX_DELETED
    end

    it "can not delete mailbox alias." do
      expect(exit_capture { Runner.start(['delete_alias', 'user@example.com']) }).to match /Can not delete mailbox/
    end

    it "can not add an alias for existed mailbox" do
      expect(exit_capture { Runner.start(['add_alias', 'user@example.com', 'goto@example.jp']) }).to match /Mailbox has already been registered: user@example\.com/
    end
  end

  describe "edit_alias" do
    it "can update active status" do
      output = capture(:stdout) { Runner.start(['edit_alias', 'alias@example.com', '--no-active']) }
      expect(output).to match EX_UPDATED
      expect(output).to match /Active.+Inactive/
    end

    it "can update goto" do
      output = capture(:stdout) { Runner.start(['edit_alias', 'alias@example.com', '-g', 'goto@example.com,user@example.com']) }
      expect(output).to match EX_UPDATED
      expect(Alias.find('alias@example.com').goto).to eq 'goto@example.com,user@example.com'
    end
  end

  describe "add_admin" do
    before do
      @args = ['add_admin', 'admin@example.jp', 'password']
    end

    it "can add an new admin" do
      expect(capture(:stdout) { Runner.start(@args) }).to match EX_REGISTERED
    end

    describe "scheme option" do
      it "--scheme does not show error" do
        expect(exit_capture { Runner.start(@args + ['--scheme', 'CRAM-MD5']) }).to eq ""
        expect(Admin.find('admin@example.jp').password).to eq CRAM_MD5_PASS
      end

      it "--shceme can register admin" do
        expect(capture(:stdout) { Runner.start(@args + ['--scheme', 'CRAM-MD5']) }).to match EX_REGISTERED
      end

      it "-s does not show error" do
        expect(exit_capture { Runner.start(@args + ['-s', 'CRAM-MD5']) }).to eq ""
      end

      it "-s can register admin" do
        expect(capture(:stdout) { Runner.start(@args + ['-s', 'CRAM-MD5']) }).to match EX_REGISTERED
      end

      it "-s require argument" do
        expect(exit_capture { Runner.start(@args + ['-s']) }).to match /Specify password scheme/
      end
    end

    it "can use long password" do
      expect(capture(:stdout) { Runner.start(['add_admin', 'admin@example.jp', '{CRAM-MD5}9c5e77f2da26fc03e9fa9e13ccd77aeb50c85539a4d90b70812715aea9ebda1d']) }).to match EX_REGISTERED
    end

    it "--super option" do
      expect(capture(:stdout) { Runner.start(@args + ['--super']) }).to match /registered as a super admin/
    end

    it "-S (--super) option" do
      expect(capture(:stdout) { Runner.start(@args + ['-S']) }).to match /registered as a super admin/
    end
  end

  describe "edit_admin" do
    it "when no options, shows usage" do
      expect(capture(:stderr) { Runner.start(['edit_admin', 'admin@example.com']) }).to match /Use one or more options/
    end

    it "can update active status" do
      output = capture(:stdout) { Runner.start(['edit_admin', 'admin@example.com', '--no-active']) }
      expect(output).to match EX_UPDATED
      expect(output).to match /Active.+Inactive/
      expect(output).to match /Role.+Admin/
    end

    it "can update super admin status" do
      output = capture(:stdout) {
        Runner.start(['edit_admin', 'admin@example.com', '--super'])
      }
      expect(output).to match EX_UPDATED
      expect(output).to match /Domains.+ALL/
      expect(output).to match /Active.+Active/
      expect(output).to match /Role.+Super admin/
    end
  end

  describe "edit_domain" do
    it "when no options, shows usage" do
      expect(exit_capture { Runner.start(['edit_domain', 'example.com']) }).to match /Use one or more options/
    end

    it "can edit limitations of domain" do
      output = capture(:stdout) { Runner.start(['edit_domain', 'example.com', '--aliases', '40', '--mailboxes', '40', '--maxquota', '400', '--no-active']) }
      expect(output).to match EX_UPDATED
      expect(output).to match /Active.+Inactive/
    end

    it "aliases options -a, -m, -q" do
      expect(capture(:stdout) { Runner.start(['edit_domain', 'example.com', '-a', '40', '-m', '40', '-m', '400']) }).to match EX_UPDATED
    end

    it "can not use unknown domain" do
      expect(exit_capture { Runner.start(['edit_domain', 'unknown.example.com', '--aliases', '40', '--mailboxes', '40', '--maxquota', '400']) }).to match /Could not find/
    end
  end

  describe "edit_account" do
    before do
      @args = ['edit_account', 'user@example.com']
    end

    it "when no options, shows usage" do
      expect(exit_capture { Runner.start(@args) }).to match /Use one or more options/
    end

    it "can edit quota limitation" do
      output = capture(:stdout) { Runner.start(@args + ['--quota', '50', '--no-active']) }
      expect(output).to match EX_UPDATED
      expect(output).to match /Quota/
      expect(output).to match /Active.+Inactive/
    end

    it "can use alias -q option" do
      expect(capture(:stdout) { Runner.start(@args + ['-q', '50']) }).to match EX_UPDATED
    end

    it "-q option require an argment" do
      expect(exit_capture { Runner.start(@args + ['-q']) }).to_not eq ""
    end

    it "can update name using --name option" do
      expect(capture(:stdout) { Runner.start(@args + ['--name', 'Hitoshi Kurokawa']) }).to match EX_UPDATED
      expect(Mailbox.find('user@example.com').name).to eq 'Hitoshi Kurokawa'
    end

    it "can update name using -n option" do
      expect(capture(:stdout) { Runner.start(@args + ['-n', 'Hitoshi Kurokawa']) }).to match EX_UPDATED
      expect(Mailbox.find('user@example.com').name).to eq 'Hitoshi Kurokawa'
    end

    it "-n option supports Japanese" do
      expect(capture(:stdout) { Runner.start(@args + ['-n', '黒川　仁']) }).to match EX_UPDATED
      expect(Mailbox.find('user@example.com').name).to eq '黒川　仁'
    end

    it "-n option require an argument" do
      expect(exit_capture { Runner.start(@args + ['-n']) }).to_not eq ""
    end

    it "can update goto" do
      expect(capture(:stdout) { Runner.start(@args + ['-g', 'user@example.com,forward@example.com']) }).to match EX_UPDATED
      expect(Alias.find('user@example.com').goto).to eq 'user@example.com,forward@example.com'
    end
  end

  it "add_admin_domain" do
    expect(capture(:stdout) { Runner.start(['add_admin_domain', 'admin@example.com', 'example.org']) }).to match EX_REGISTERED
  end

  it "delete_admin_domain" do
    expect(capture(:stdout) { Runner.start(['delete_admin_domain', 'admin@example.com', 'example.com']) }).to match EX_DELETED
  end

  it "delete_admin" do
    expect(capture(:stdout) { Runner.start(['delete_admin', 'admin@example.com']) }).to match EX_DELETED
  end

  it "add_account and delete_account" do
    expect(capture(:stdout) { Runner.start(['add_account', 'user2@example.com', 'password']) }).to match EX_REGISTERED
    expect(capture(:stdout) { Runner.start(['delete_account', 'user2@example.com']) }).to match EX_DELETED
  end

  describe "add_account" do
    before do
      @user = 'user2@example.com'
      @args = ['add_account', @user, 'password']
      @name = 'Hitoshi Kurokawa'
    end

    it "default scheme (CRAM-MD5) is applied" do
      expect(capture(:stdout) { Runner.start(@args) }).to match /scheme: CRAM-MD5/
      expect(Mailbox.find('user2@example.com').password).to eq CRAM_MD5_PASS
    end

    it "add_account can use long password" do
      expect(capture(:stdout) { Runner.start(['add_account', 'user2@example.com', '{CRAM-MD5}9c5e77f2da26fc03e9fa9e13ccd77aeb50c85539a4d90b70812715aea9ebda1d']) }).to match EX_REGISTERED
    end

    describe "name option" do
      it "--name options does not raise error" do
        expect(exit_capture { Runner.start(@args + ['--name', @name]) }).to eq ""
      end

      it "-n options does not raise error" do
        expect(exit_capture { Runner.start(@args + ['-n', @name]) }).to eq ""
      end

      it "require an argument" do
        expect(exit_capture { Runner.start(@args + ['-n']) }).to_not eq ""
      end

      it "can change full name" do
        Runner.start(@args + ['-n', @name])
        expect(Mailbox.find(@user).name).to eq @name
      end

      it "can use Japanese" do
        expect(exit_capture { Runner.start(@args + ['-n', '黒川　仁']) }).to eq ""
        expect(Mailbox.find(@user).name).to eq '黒川　仁'
      end
    end

    describe "scheme" do
      it "--scheme require argument" do
        expect(exit_capture { Runner.start(@args + ['--scheme']) }).to match /Specify password scheme/
      end

      it "can use CRAM-MD5 using --scheme" do
        expect(capture(:stdout) { Runner.start(@args + ['--scheme', 'CRAM-MD5']) }).to match EX_REGISTERED
        expect(Mailbox.find('user2@example.com').password).to eq CRAM_MD5_PASS
      end

      it "can use CRAM-MD5 using -s" do
        expect(capture(:stdout) { Runner.start(@args + ['-s', 'CRAM-MD5']) }).to match EX_REGISTERED
        expect(Mailbox.find('user2@example.com').password).to eq CRAM_MD5_PASS
      end

      it "can use MD5-CRYPT using -s" do
        result = capture(:stdout) { Runner.start(@args + ['-s', 'MD5-CRYPT']) }
        expect(result).to match EX_REGISTERED
        expect(result).to match /scheme: MD5-CRYPT/
        expect(Mailbox.find('user2@example.com').password).to match EX_MD5_CRYPT
      end
    end
  end

  describe "log" do
    it "does not raise error" do
      expect(exit_capture { Runner.start(['log']) }).to eq ""
    end
  end

  describe "dump" do
    it "does not raise error" do
      expect(exit_capture { Runner.start(['dump']) }).to eq ""
    end

    it "all data" do
      result = capture(:stdout) { Runner.start(['dump']) }
      expect(result).to match /Domains/
    end
  end
end
