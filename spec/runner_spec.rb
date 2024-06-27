require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/runner'

RSpec.describe PostfixAdmin::Runner do
  before do
    db_initialize
  end

  describe "usual work flow with add/delete methods" do
    it "does not raise an error" do
      expect do
        silent do
          # Use add_domain subcommand
          Runner.start(%w[add_domain new-domain.test])
          Runner.start(%w[add_admin admin@new-domain.test password])
          Runner.start(%w[add_admin_domain admin@new-domain.test new-domain.test])

          Runner.start(%w[add_account user1@new-domain.test password])
          Runner.start(%w[add_account user2@new-domain.test password])
          Runner.start(%w[add_alias alias1@new-domain.test goto1@@new-domain2.test])
          Runner.start(%w[add_alias alias2@new-domain.test goto2@@new-domain2.test])
          Runner.start(%w[delete_account user2@new-domain.test])
          Runner.start(%w[delete_alias alias2@new-domain.test])
          Runner.start(%w[delete_domain new-domain.test])

          # Use setup subcommand
          Runner.start(%w[setup new-domain2.test password])
          Runner.start(%w[add_account user1@new-domain2.test password])
          Runner.start(%w[add_account user2@new-domain2.test password])
          Runner.start(%w[add_alias alias1@new-domain2.test goto1@@new-domain2.test])
          Runner.start(%w[add_alias alias2@new-domain2.test goto2@@new-domain2.test])
          Runner.start(%w[delete_account user2@new-domain2.test])
          Runner.start(%w[delete_alias alias2@new-domain2.test])
          Runner.start(%w[delete_domain new-domain2.test])
        end
      end.not_to raise_error
    end
  end

  describe "#version" do
    it "matches the version pattern" do
      res = capture(:stdout) { Runner.start(["version"]) }
      expect(res).to match(/postfix_admin \d+\.\d+\.\d/)
    end
  end

  describe "#schemes" do
    it "includes the expected schemes" do
      res = capture(:stdout) { Runner.start(["schemes"]) }
      schemes = res.split
      expect(schemes).to include("CRAM-MD5")
      expect(schemes).to include("CLEARTEXT")
    end
  end

  describe "#summary" do
    it "contains the expected summary keys" do
      res = capture(:stdout) { Runner.start(["summary"]) }
      list = parse_table(res)
      keys = list.keys

      expect(res).to match(/\| Summary \|/)
      expect(keys).to include("Admins")
      expect(keys).to include("Mailboxes")
      expect(keys).to include("Aliases")
    end

    context "with domain" do
      it "contains the expected domain summary and updates quota" do
        res = capture { Runner.start(%w[summary example.com]) }
        list = parse_table(res)
        keys = list.keys

        expect(res).to match(/\| example.com \|/)
        expect(keys).to include("Mailboxes")
        expect(keys).to include("Aliases")
        expect(list["Max Quota (MB)"]).to eq("100")
        expect(list["Active"]).to eq("Active")
        expect(res).to match(/Description[|\s]+example.com Description/)
        expect(list["Description"]).to eq("example.com Description")

        # set maxquota to 0 (unlimited)
        Domain.find("example.com").update(maxquota: 0)
        res = capture { Runner.start(%w[summary example.com]) }
        list = parse_table(res)
        expect(list["Max Quota (MB)"]).to eq("Unlimited")
      end
    end
  end

  describe "#show" do
    it "shows information of example.com" do
      expect(capture(:stdout) { Runner.start(["show"]) }).to match \
        /example.com[|\s]+1[|\s]+\/[|\s]+30[|\s]+1[|\s]+\/[|\s]+30[|\s]+100[|\s]+Active[|\s]+example.com Description/
    end

    it "shows information of admin@example.com" do
      out = capture(:stdout) { Runner.start(["show"]) }
      expect(out).to match /admin@example.com[|\s]+1[|\s]+Active[|\s]+\{CRAM-MD5\}/
    end

    it "show the detail of example.com" do
      expect(capture(:stdout) { Runner.start(["show", "example.com"]) }).to \
        match /user@example.com[|\s]+100[|\s]+Active[|\s]+\{CRAM-MD5\}/
    end

    it "when no admins, no aliases and no addresses" do
      Admin.find('all@example.com').super_admin = false
      out = capture(:stdout) { Runner.start(["show", "example.org"]) }
      expect(out).to match /No admins/
      expect(out).to match /No addresses/
      expect(out).to match /No aliases/
    end

    it "shows information of an admin" do
      out = capture(:stdout) {  Runner.start(["show", "admin@example.com"]) }
      expect(out).to match /admin@example.com/
      expect(out).to match /Password/
    end

    it "shows information of an account" do
      out = capture(:stdout) { Runner.start(["show", "user@example.com"]) }
      expect(out).to match /user@example.com/
      expect(out).to match /Password/
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

  describe "#add_domain" do
    it "adds a new Domain" do
      expect {
        res = capture { Runner.start(%w[add_domain new-domain.test -d NewDomain]) }
        expect(res).to match('"new-domain.test" was successfully registered as a domain')
      }.to change { Domain.count }.by(1)
      expect(Domain.exists?("new-domain.test")).to be true
      expect(Domain.find("new-domain.test").description).to eq("NewDomain")
    end
  end

  describe "#delete_domain" do
    it "deletes a Domain" do
      expect(Domain.exists?("example.com")).to be true
      expect {
        res = capture { Runner.start(%w[delete_domain example.com]) }
        expect(res).to match('"example.com" was successfully deleted')
      }.to change { Domain.count }.by(-1)
      expect(Domain.exists?("example.com")).to be false
    end
  end

  describe "#admin_passwd" do
    before do
      @admin = Admin.find("admin@example.com")
      @args = %w[admin_passwd admin@example.com new_password]
    end

    it "can change password of an admin" do
      expect(capture(:stdout) { Runner.start(@args) }).to match EX_UPDATED
      expect(@admin.reload.password).to eq CRAM_MD5_NEW_PASS
    end

    context "with scheme option" do
      %w[--scheme -s].each do |s_opt|
        it "'#{s_opt}' allows to set password schema" do
          expect(capture(:stdout) {
            Runner.start(@args + [s_opt, "BLF-CRYPT"])
          }).to match EX_UPDATED
          expect(@admin.reload.password).to match EX_BLF_CRYPT

          # doveadm pw -u admin@example.com -s DIGEST-MD5 -p new_password
          # {DIGEST-MD5}d08d89dcc9ed079cba21cd9083c30b9b
          expect(capture(:stdout) {
            Runner.start(@args + [s_opt, "DIGEST-MD5"])
          }).to match EX_UPDATED
          expect(@admin.reload.password).to eq "{DIGEST-MD5}d08d89dcc9ed079cba21cd9083c30b9b"
        end

        %w[--rounds -r].each do |r_opt|
          it "'#{r_opt}' allows to set rounds" do
            expect(capture(:stdout) {
              Runner.start(@args + [s_opt, "BLF-CRYPT", r_opt, "13"])
            }).to match EX_UPDATED

            expect(@admin.reload.password).to match EX_BLF_CRYPT_ROUNDS_13
          end
        end
      end
    end

    it "can not use too short password (< 5)" do
      expect(exit_capture {
        Runner.start(['admin_passwd', 'admin@example.com', '124'])
      }).to match /too short/
    end

    it "can not use for unknown admin" do
      expect(exit_capture {
        Runner.start(['admin_passwd', 'unknown@example.com', 'new_password'])
      }).to match /Could not find/
    end
  end

  describe "#account_passwd" do
    before do
      @mailbox = Mailbox.find("user@example.com")
      @args = %w[account_passwd user@example.com new_password]
    end

    it "can change password of an account" do
      expect(capture(:stdout) { Runner.start(@args) }).to match EX_UPDATED
      expect(@mailbox.reload.password).to eq CRAM_MD5_NEW_PASS
    end

    context "with scheme option" do
      %w[--scheme -s].each do |s_opt|
        it "'#{s_opt}' allows to set password schema" do
          expect(capture(:stdout) {
            Runner.start(@args + [s_opt, "BLF-CRYPT"])
          }).to match EX_UPDATED
          expect(@mailbox.reload.password).to match EX_BLF_CRYPT_ROUNDS_10

          # doveadm pw -u user@example.com -s DIGEST-MD5 -p new_password
          # {DIGEST-MD5}b2b609fd153bc5f2e57d2788626c9aad
          expect(capture(:stdout) {
            Runner.start(@args + [s_opt, "DIGEST-MD5"])
          }).to match EX_UPDATED
          expect(@mailbox.reload.password).to eq "{DIGEST-MD5}b2b609fd153bc5f2e57d2788626c9aad"
        end

        %w[--rounds -r].each do |r_opt|
          it "'#{r_opt}' allows to set rounds" do
            expect(capture(:stdout) {
              Runner.start(@args + [s_opt, "BLF-CRYPT", r_opt, "13"])
            }).to match EX_UPDATED

            expect(@mailbox.reload.password).to match EX_BLF_CRYPT_ROUNDS_13
          end
        end
      end
    end

    it "can not use too short password (< 5)" do
      expect(exit_capture {
        Runner.start(['account_passwd', 'user@example.com', '1234'])
      }).to match /too short/
    end

    it "can not use for unknown account" do
      expect(exit_capture {
        Runner.start(['account_passwd', 'unknown@example.com', 'new_password'])
      }).to match /Could not find/
    end
  end

  describe "#edit_alias" do
    it "can update active status" do
      output = capture(:stdout) { Runner.start(['edit_alias', 'alias@example.com', '--no-active']) }
      expect(output).to match EX_UPDATED
      expect(Alias.find('alias@example.com').active).to be false
    end

    it "can update goto" do
      output = capture(:stdout) { Runner.start(['edit_alias', 'alias@example.com', '-g', 'goto@example.com,user@example.com']) }
      expect(output).to match EX_UPDATED
      expect(Alias.find('alias@example.com').goto).to eq 'goto@example.com,user@example.com'
    end
  end

  describe "#add_admin" do
    before do
      @args = %w[add_admin admin@new-domain.test password]
    end

    it "can add an new admin user" do
      expect(capture(:stdout) {
        expect{ Runner.start(@args) }.to change{ Admin.count }.by(1)
      }).to match EX_REGISTERED
      expect(Admin.exists?("admin@new-domain.test")).to be true
      admin = Admin.find("admin@new-domain.test")
      # default scheme CRAM-MD5
      expect(admin.password).to eq CRAM_MD5_PASS
    end

    context "with scheme option" do
      %w[--scheme -s].each do |s_opt|
        it "'#{s_opt}' allows to set password schema" do
          expect(capture(:stdout) {
            Runner.start(@args + [s_opt, "BLF-CRYPT"])
          }).to match EX_REGISTERED
          expect(Admin.find("admin@new-domain.test").password).to \
            match EX_BLF_CRYPT
        end

        # doveadm pw -u admin@new-domain.test -s DIGEST-MD5 -p password
        # {DIGEST-MD5}a8f914093e24bac3aabd5eaa1217d72f
        it "'#{s_opt}' allows to set DIGEST-MD5 schema" do
          expect(capture(:stdout) {
            Runner.start(@args + [s_opt, "DIGEST-MD5"])
          }).to match EX_REGISTERED
          expect(Admin.find("admin@new-domain.test").password).to \
            eq "{DIGEST-MD5}a8f914093e24bac3aabd5eaa1217d72f"
        end

        it "'#{s_opt}' requires argument" do
          expect(exit_capture { Runner.start(@args + ['-s']) }).to \
            match /Specify password scheme/
        end

        %w[--rounds -r].each do |r_opt|
          it "'#{r_opt}' allows to set rounds" do
            expect(capture(:stdout) {
              Runner.start(@args + [s_opt, "BLF-CRYPT", r_opt, "13"])
            }).to match EX_REGISTERED

            expect(Admin.find("admin@new-domain.test").password).to \
              match EX_BLF_CRYPT_ROUNDS_13
          end
        end
      end
    end

    it "can use long password" do
      expect(capture(:stdout) { Runner.start(['add_admin', "admin@new-domain.test", '{CRAM-MD5}9c5e77f2da26fc03e9fa9e13ccd77aeb50c85539a4d90b70812715aea9ebda1d']) }).to match EX_REGISTERED
    end

    it "--super option" do
      expect(capture(:stdout) { Runner.start(@args + ['--super']) }).to \
        match /registered as a super admin/
    end

    it "-S (--super) option" do
      expect(capture(:stdout) { Runner.start(@args + ['-S']) }).to \
        match /registered as a super admin/
    end
  end

  describe "#delete_admin" do
    it "deletes an Admin" do
      expect(Admin.exists?("admin@example.com")).to be true
      expect {
        res = capture { Runner.start(%w[delete_admin admin@example.com]) }
        expect(res).to match('"admin@example.com" was successfully deleted')
      }.to change { Admin.count }.by(-1)
      expect(Admin.exists?("admin@example.com")).to be false
    end
  end

  describe "#edit_admin" do
    it "when no options, shows usage" do
      expect(capture(:stderr) {
        Runner.start(['edit_admin', 'admin@example.com'])
      }).to match /Use one or more options/
    end

    it "can update active status" do
      admin = Admin.find('admin@example.com')
      expect(admin.active).to be true
      output = capture(:stdout) { Runner.start(['edit_admin', 'admin@example.com', '--no-active']) }
      expect(output).to match EX_UPDATED
      expect(admin.reload.active).to be false
      expect(output).not_to match /Password/
      expect(output).to match /Role.+Standard Admin/
    end

    it "can update super admin status" do
      admin = Admin.find('admin@example.com')
      expect(admin.super_admin?).to be false
      output = capture(:stdout) {
        Runner.start(['edit_admin', 'admin@example.com', '--super'])
      }
      expect(output).to match EX_UPDATED
      expect(admin.reload.super_admin?).to be true
      expect(output).to match /Domains.+ALL/
      expect(output).to match /Active.+Active/
      expect(output).to match /Role.+Super Admin/
    end
  end

  describe "#edit_domain" do
    it "when no options, shows usage" do
      expect(exit_capture {
        Runner.start(['edit_domain', 'example.com'])
      }).to match /Use one or more options/
    end

    it "can edit limitations of domain" do
      output = capture(:stdout) { Runner.start(['edit_domain', 'example.com', '--aliases', '40', '--mailboxes', '40', '--maxquota', '400', '--no-active']) }
      expect(output).to match EX_UPDATED
      expect(output).to match /Active.+Inactive/
    end

    it "can edit description" do
      output = capture(:stdout) { Runner.start(['edit_domain', 'example.com', '-d', 'New Description']) }
      expect(output).to match EX_UPDATED
      domain = Domain.find('example.com')
      expect(domain.description).to eq "New Description"
    end

    it "aliases options -a, -m, -q" do
      expect(capture(:stdout) { Runner.start(['edit_domain', 'example.com', '-a', '40', '-m', '40', '-m', '400']) }).to match EX_UPDATED
    end

    it "can not use unknown domain" do
      expect(exit_capture { Runner.start(['edit_domain', 'unknown.example.com', '--aliases', '40', '--mailboxes', '40', '--maxquota', '400']) }).to match /Could not find/
    end
  end

  describe "#add_admin_domain" do
    it "adds a DomainAdmin" do
      create(:admin, username: "new-admin@example.com")
      expect {
        res = capture { Runner.start(%w[add_admin_domain new-admin@example.com example.com]) }
        expect(res).to match('"example.com" was successfully registered as a domain of new-admin@example.com')
      }.to change { DomainAdmin.count }.by(1)
      admin = Admin.find("new-admin@example.com")
      expect(admin.rel_domains.exists?("example.com")).to be true
    end
  end

  describe "#delete_admin_domain" do
    it "deletes a DomainAdmin" do
      admin = Admin.find("admin@example.com")
      expect(admin.rel_domains.exists?("example.com")).to be true
      expect {
        res = capture { Runner.start(%w[delete_admin_domain admin@example.com example.com]) }
        expect(res).to match("example.com was successfully deleted from admin@example.com")
      }.to change { DomainAdmin.count }.by(-1)
      admin.reload
      expect(admin.rel_domains.exists?("example.com")).to be false
    end
  end

  describe "#edit_account" do
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
      expect(output).not_to match /Password/
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

  describe "#add_account" do
    before do
      @user = 'user2@example.com'
      @args = ['add_account', @user, 'password']
      @name = 'Hitoshi Kurokawa'
    end

    it "adds a Mailbox and an Alias" do
      expect {
        res = capture { Runner.start(@args) }
        expect(res).to match(%!"#{@user}" was successfully registered as an account!)
      }.to change{ Mailbox.count }.by(1).and change{ Alias.count }.by(1)

      expect(Mailbox.exists?(@user)).to be true
      expect(Alias.exists?(@user)).to be true
      mailbox = Mailbox.find(@user)
      expected = "{CRAM-MD5}9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740"
      expect(mailbox.password).to eq(expected)
    end

    it "default scheme (CRAM-MD5) is applied" do
      expect(capture(:stdout) { Runner.start(@args) }).to match EX_REGISTERED
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
        capture(:stdout) { Runner.start(@args + ['-n', @name]) }
        expect(Mailbox.find(@user).name).to eq @name
      end

      it "can use Japanese" do
        expect(exit_capture { Runner.start(@args + ['-n', '黒川　仁']) }).to eq ""
        expect(Mailbox.find(@user).name).to eq '黒川　仁'
      end
    end

    context "with scheme option" do
      %w[--scheme -s].each do |s_opt|
        it "'#{s_opt}' allows to set password schema" do
          expect(capture(:stdout) {
            Runner.start(@args + [s_opt, "BLF-CRYPT"])
          }).to match EX_REGISTERED
          expect(Mailbox.find(@user).password).to match EX_BLF_CRYPT
        end

        # doveadm pw -u user2@example.com -s DIGEST-MD5 -p password
        # {DIGEST-MD5}0fe1fb25d6134c9df70eb79d88c91ff5
        it "'#{s_opt}' allows to set DIGEST-MD5 schema" do
          expect(capture(:stdout) {
            Runner.start(@args + [s_opt, "DIGEST-MD5"])
          }).to match EX_REGISTERED
          expect(Mailbox.find(@user).password).to \
            eq "{DIGEST-MD5}0fe1fb25d6134c9df70eb79d88c91ff5"
        end

        it "'#{s_opt}' requires argument" do
          expect(exit_capture { Runner.start(@args + [s_opt]) }).to \
            match /Specify password scheme/
        end

        %w[--rounds -r].each do |r_opt|
          it "'#{r_opt}' allows to set rounds" do
            expect(capture(:stdout) {
              Runner.start(@args + [s_opt, "BLF-CRYPT", r_opt, "13"])
            }).to match EX_REGISTERED

            expect(Mailbox.find(@user).password).to \
              match EX_BLF_CRYPT_ROUNDS_13
          end
        end
      end
    end
  end

  describe "#delete_account" do
    it "deletes a Mailbox and an Alias" do
      expect(Alias.exists?("user@example.com")).to be true
      expect(Mailbox.exists?("user@example.com")).to be true

      expect {
        res = capture { Runner.start(%w[delete_account user@example.com]) }
        expect(res).to match('"user@example.com" was successfully deleted')
      }.to change{ Mailbox.count }.by(-1).and change{ Alias.count }.by(-1)

      expect(Alias.exists?("user@example.com")).to be false
      expect(Mailbox.exists?("user@example.com")).to be false
    end
  end

  describe "#setup" do
    before do
      @admin = "admin@new-domain.test"
      @args = %w[setup new-domain.test password]
    end
    
    it "setup adds a Domain and an Admin for it" do
      res = capture(:stdout) do
        expect{
          Runner.start(@args)
        }.to change{ Admin.count }.by(1).and \
             change{ Domain.count }.by(1).and \
             change{ DomainAdmin.count }.by(1)
      end

      expect(res).to match '"new-domain.test" was successfully registered as a domain'
      expect(res).to match '"admin@new-domain.test" was successfully registered as an admin'
      expect(res).to match '"new-domain.test" was successfully registered as a domain of admin@new-domain.test'

      expect(Domain.exists?("new-domain.test")).to be true
      expect(Admin.exists?(@admin)).to be true
      admin = Admin.find(@admin)
      expect(admin.rel_domains.exists?("new-domain.test")).to be true
    end

    context "with scheme option" do
      %w[--scheme -s].each do |s_opt|
        it "'#{s_opt}' allows to set password schema" do
          expect(capture(:stdout) {
            Runner.start(@args + [s_opt, "BLF-CRYPT"])
          }).to match EX_REGISTERED
          expect(Admin.find(@admin).password).to match EX_BLF_CRYPT
        end

        # doveadm pw -u admin@new-domain.test -s DIGEST-MD5 -p password
        # {DIGEST-MD5}a8f914093e24bac3aabd5eaa1217d72f
        it "'#{s_opt}' allows to set DIGEST-MD5 schema" do
          expect(capture(:stdout) {
            Runner.start(@args + [s_opt, "DIGEST-MD5"])
          }).to match EX_REGISTERED
          expect(Admin.find(@admin).password).to \
            eq "{DIGEST-MD5}a8f914093e24bac3aabd5eaa1217d72f"
        end

        %w[--rounds -r].each do |r_opt|
          it "'#{r_opt}' allows to set rounds" do
            expect(capture(:stdout) {
              Runner.start(@args + [s_opt, "BLF-CRYPT", r_opt, "13"])
            }).to match EX_REGISTERED

            expect(Admin.find(@admin).password).to match EX_BLF_CRYPT_ROUNDS_13
          end
        end
      end
    end
  end

  describe "#log" do
    it "does not raise an error" do
      expect { silent { Runner.start(["log"]) } }.not_to raise_error
    end

    context "with domain filter" do
      it "does not raise an error" do
        expect { silent { Runner.start(%w[log -d example.com]) } }.not_to raise_error
      end
    end

    context "with lines" do
      it "does not raise an error" do
        expect { silent { Runner.start(%w[log -l 100]) } }.not_to raise_error
      end
    end
  end

  describe "#dump" do
    it "does not raise an error and matches expected output" do
      expect {
        res = capture(:stdout) { Runner.start(["dump"]) }
        expect(res).to match(/Domains/)
        expect(res).to match(/example.com/)
        expect(res).to match(/admin@example.com/)
      }.not_to raise_error
    end
  end
end
