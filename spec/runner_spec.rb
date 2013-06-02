require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/runner'

describe PostfixAdmin::Runner do
  before do
    db_initialize
  end

  it "version" do
    capture(:stdout){ Runner.start(["version"]) }.should =~ /postfix_admin \d+\.\d+\.\d/
  end

  it "summary" do
    capture(:stdout){ Runner.start(["summary"]) }.should =~ /\[Summary\]/
    capture(:stdout){ Runner.start(["summary", "example.com"]) }.should =~ /\[Summary of example.com\]/
  end

  describe "show" do
    it "shows information of example.com" do
     capture(:stdout){ Runner.start(["show"]) }.should =~ /example.com\s+1\s+\/\s+30\s+1\s+\/\s+30\s+100/
    end

    it "shows information of admin@example.com" do
      capture(:stdout){ Runner.start(["show"]) }.should =~ /admin@example.com\s+1\s+YES/
    end

    it "show the detail of example.com" do
      capture(:stdout){ Runner.start(["show", "example.com"]) }.should =~ /user@example.com\s+100\s+YES/
    end

    it "when no admins, no aliases and no addresses" do
      Admin.find('all@example.com').super_admin = false
      out = capture(:stdout){ Runner.start(["show", "example.org"]) }
      out.should =~ /No admins/
      out.should =~ /No addresses/
      out.should =~ /No aliases/
    end

    it "shows information of an account" do
      capture(:stdout){  Runner.start(["show", "user@example.com"]) }.should =~ /user@example.com/
    end

    it "when no domains" do
      capture(:stdout){ Runner.start(['delete_domain', 'example.com']) }.should =~ EX_DELETED
      capture(:stdout){ Runner.start(['delete_domain', 'example.org']) }.should =~ EX_DELETED
      capture(:stdout){ Runner.start(["show"]) }.should =~ /No domains/
    end
  end

  it "setup" do
    capture(:stdout){ Runner.start(['setup', 'example.net', 'password']) }.should =~ EX_REGISTERED
    capture(:stdout){ Runner.start(['delete_domain', 'example.net']) }.should =~ EX_DELETED
  end

  describe "super_admin" do
    it "can enable super admin flag of an admin" do
      capture(:stdout){ Runner.start(['super', 'admin@example.com']) }.should =~ /Successfully enabled/
    end

    it "can disable super admin flag of an admin (--disable)" do
      capture(:stdout){ Runner.start(['super', 'admin@example.com', '--disable']) }.should =~ /Successfully disabled/
    end

    it "can use -d option as --disable" do
      capture(:stdout){ Runner.start(['super', 'admin@example.com', '-d']) }.should =~ /Successfully disabled/
    end
  end

  describe "admin_passwd" do
    it "can change password of an admin" do
      capture(:stdout){ Runner.start(['admin_passwd', 'admin@example.com', 'new_password']) }.should =~ /successfully changed/
    end

    it "can not use too short password (< 5)" do
      capture(:stderr){ Runner.start(['admin_passwd', 'admin@example.com', '124']) }.should =~ /too short/
    end

    it "can not use for unknown admin" do
      capture(:stderr){ Runner.start(['admin_passwd', 'unknown@example.com', 'new_password']) }.should =~ /Could not find/
    end
  end

  describe "account_passwd" do
    it "can change password of an account" do
      capture(:stdout){ Runner.start(['account_passwd', 'user@example.com', 'new_password']) }.should =~ /successfully changed/
    end

    it "can not use too short password (< 5)" do
      capture(:stderr){ Runner.start(['account_passwd', 'user@example.com', '1234']) }.should =~ /too short/
    end

    it "can not use for unknown account" do
      capture(:stderr){ Runner.start(['account_passwd', 'unknown@example.com', 'new_password']) }.should =~ /Could not find/
    end
  end

  describe "add_alias and delete_alias" do
    it "can add and delete an new alias." do
      capture(:stdout){ Runner.start(['add_alias', 'new_alias@example.com', 'goto@example.jp']) }.should =~ EX_REGISTERED
      capture(:stdout){ Runner.start(['delete_alias', 'new_alias@example.com']) }.should =~ EX_DELETED
    end

    it "can not delete mailbox alias." do
      capture(:stderr){ Runner.start(['delete_alias', 'user@example.com']) }.should =~ /Can not delete mailbox/
    end

    it "can not add an alias for existed mailbox" do
      capture(:stderr){ Runner.start(['add_alias', 'user@example.com', 'goto@example.jp']) }.should =~ /mailbox user@example.com is already registered!/
    end
  end

  describe "add_admin" do
    it "can add an new admin" do
      capture(:stdout){ Runner.start(['add_admin', 'admin@example.jp', 'password']) }.should =~ EX_REGISTERED
    end

    describe "scheme option" do
      it "--scheme does not show error" do
        capture(:stderr){ Runner.start(['add_admin', 'admin@example.jp', 'password', '--scheme', 'CRAM-MD5']) }.should == ""
        Admin.find('admin@example.jp').password.should == '9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740'
      end

      it "--shceme can resister admin" do
        capture(:stdout){ Runner.start(['add_admin', 'admin@example.jp', 'password', '--scheme', 'CRAM-MD5']) }.should =~ EX_REGISTERED
      end

      it "-s does not show error" do
        capture(:stderr){ Runner.start(['add_admin', 'admin@example.jp', 'password', '-s', 'CRAM-MD5']) }.should == ""
      end

      it "-s can resister admin" do
        capture(:stdout){ Runner.start(['add_admin', 'admin@example.jp', 'password', '-s', 'CRAM-MD5']) }.should =~ EX_REGISTERED
      end

      it "-s require argument" do
        capture(:stderr){ Runner.start(['add_admin', 'admin@example.jp', 'password', '-s']) }.should_not == ""
      end
    end

    it "can use long password" do
      capture(:stdout){ Runner.start(['add_admin', 'admin@example.jp', '9c5e77f2da26fc03e9fa9e13ccd77aeb50c85539a4d90b70812715aea9ebda1d']) }.should =~ EX_REGISTERED
    end

    it "--super option" do
      capture(:stdout){ Runner.start(['add_admin', 'admin@example.jp', 'password', '--super']) }.should =~ /registered as a super admin/
    end

    it "-S (--super) option" do
      capture(:stdout){ Runner.start(['add_admin', 'admin@example.jp', 'password', '-S']) }.should =~ /registered as a super admin/
    end
  end

  describe "edit_domain" do
    it "when no options, shows usage" do
      capture(:stderr){ Runner.start(['edit_domain', 'example.com']) }.should =~ /Use one or more options/
    end

    it "can edit limitations of domain" do
      capture(:stdout){ Runner.start(['edit_domain', 'example.com', '--aliases', '40', '--mailboxes', '40', '--maxquota', '400']) }.should =~ /Successfully updated/
    end

    it "aliases options -a, -m, -q" do
      capture(:stdout){ Runner.start(['edit_domain', 'example.com', '-a', '40', '-m', '40', '-m', '400']) }.should =~ /Successfully updated/
    end

    it "can not use unknown domain" do
      capture(:stderr){ Runner.start(['edit_domain', 'unknown.example.com', '--aliases', '40', '--mailboxes', '40', '--maxquota', '400'])}.should =~ /Could not find/
    end
  end

  describe "edit_account" do
    it "when no options, shows usage" do
      capture(:stderr){ Runner.start(['edit_account', 'user@example.com']) }.should =~ /Use one or more options/
    end

    it "can edit quota limitation" do
      output = capture(:stdout){ Runner.start(['edit_account', 'user@example.com', '--quota', '50'])}
      output.should =~ /Successfully updated/
      output.should =~ /Quota/
    end

    it "can use alias -q option" do
      capture(:stdout){ Runner.start(['edit_account', 'user@example.com', '-q', '50'])}.should =~ /Successfully updated/
    end
  end

  it "add_admin_domain" do
    capture(:stdout){ Runner.start(['add_admin_domain', 'admin@example.com', 'example.org']) }.should =~ EX_REGISTERED
  end

  it "delete_admin_domain" do
    capture(:stdout){ Runner.start(['delete_admin_domain', 'admin@example.com', 'example.com']) }.should =~ EX_DELETED
  end

  it "delete_admin" do
    capture(:stdout){ Runner.start(['delete_admin', 'admin@example.com']) }.should =~ EX_DELETED
  end

  it "add_account and delete_account" do
    capture(:stdout){ Runner.start(['add_account', 'user2@example.com', 'password']) }.should =~ EX_REGISTERED
    capture(:stdout){ Runner.start(['delete_account', 'user2@example.com']) }.should =~ EX_DELETED
  end

  it "add_account can use long password" do
    capture(:stdout){ Runner.start(['add_account', 'user2@example.com', '9c5e77f2da26fc03e9fa9e13ccd77aeb50c85539a4d90b70812715aea9ebda1d']) }.should =~ EX_REGISTERED
  end

  describe "scheme" do
    it "add_account can use CRAM-MD5 scheme using --scheme" do
      capture(:stdout){ Runner.start(['add_account', 'user2@example.com', 'password', '--scheme', 'CRAM-MD5']) }.should =~ EX_REGISTERED
      Mailbox.find('user2@example.com').password.should == '9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740'
    end

    it "add_account can use CRAM-MD5 scheme using -s" do
      capture(:stdout){ Runner.start(['add_account', 'user2@example.com', 'password', '-s', 'CRAM-MD5']) }.should =~ EX_REGISTERED
      Mailbox.find('user2@example.com').password.should == '9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740'
    end

    it "add_account can use MD5-CRYPT scheme using -s" do
      capture(:stdout){ Runner.start(['add_account', 'user2@example.com', 'password', '-s', 'MD5-CRYPT']) }.should =~ EX_REGISTERED
      Mailbox.find('user2@example.com').password.should =~ /^\$1\$[\.\/0-9A-Za-z]{8}\$[\.\/0-9A-Za-z]{22}$/
    end
  end

  it "add and delete methods" do
    lambda { Runner.start(['add_domain', 'example.net']) }.should_not raise_error
    Runner.start(['add_admin', 'admin@example.net', 'password'])
    Runner.start(['add_admin_domain', 'admin@example.net', 'example.net'])

    lambda { Runner.start(['add_account', 'user1@example.net', 'password']) }.should_not raise_error
    lambda { Runner.start(['add_account', 'user2@example.net', 'password']) }.should_not raise_error
    lambda { Runner.start(['delete_domain', 'example.net']) }.should_not raise_error
  end
end
