
require 'postfix_admin/cli'

describe PostfixAdmin::CLI, "when config file does not exist" do
  before do
    config_initialize
    @file = File.join(File.dirname(__FILE__) , 'tmp/postfix_admin.conf')
    CLI.config_file = @file
    FileUtils.rm(@file) if File.exist?(@file)
  end

  it "::config_file#=" do
    CLI.config_file.should == @file
  end

  it "#new should raise SystemExit and create config_file, permission should be 600" do
    lambda { CLI.new }.should raise_error SystemExit
    File.exist?(@file).should === true
    ("%o" % File.stat(@file).mode).should == "100600"
  end
end

describe PostfixAdmin::CLI do
  before do
    db_initialize
    @cli = CLI.new
  end

  describe "#show" do
    it "show all domains information by nil domain name" do
      lambda { @cli.show(nil) }.should_not raise_error
    end

    it "show domain information" do
      lambda { @cli.show('example.com') }.should_not raise_error
    end

    it "can use frozen domain name" do
      domain = 'example.com'
      lambda { @cli.show(domain.freeze) }.should_not raise_error
    end

    it "upcase will convert to downcase" do
      lambda { @cli.show('ExAmpLe.CoM') }.should_not raise_error
    end

    it "when unknown domain, raises Error" do
      lambda { @cli.show('unknown.example.com') }.should raise_error Error
    end
  end

  it "#show_domain" do
    lambda { @cli.show_domain }.should_not raise_error
    capture(:stdout){ @cli.show_domain }.should_not =~ /ALL/
  end

  describe "#show_account_details" do
    it "shows information of an account" do
      lambda {  @cli.show_account_details('user@example.com') }.should_not raise_error
      result = capture(:stdout){ @cli.show_account_details('user@example.com') }
      result.should =~ /Name/
      result.should =~ /Quota/
    end

    it "raises error when unknown account" do
      lambda {  @cli.show_account_details('unknown@example.com') }.should raise_error Error
    end
  end

  describe "#show_summary" do
    it "show summary of all domain" do
      lambda { @cli.show_summary }.should_not raise_error
    end

    it "show summary of domain" do
      lambda { @cli.show_summary('example.com') }.should_not raise_error
    end

    it "upcase will convert to downcase" do
      lambda { @cli.show_summary('example.COM') }.should_not raise_error
    end

    it "when unknown domain, raises Error" do
      lambda { @cli.show_summary('unknown.example.com') }.should raise_error Error
    end
  end

  it "#show_admin" do
    lambda { @cli.show_admin }.should_not raise_error
  end

  it "#show_address" do
    lambda { @cli.show_address('example.com') }.should_not raise_error
    lambda { @cli.show_address('unknown.example.com') }.should raise_error Error
  end

  it "#show_admin_domain" do
    lambda { @cli.show_admin_domain('admin@example.com') }.should_not raise_error
  end

  it "#show_alias" do
    lambda { @cli.show_alias('example.com') }.should_not raise_error
    lambda { @cli.show_alias('unknown.example.com') }.should raise_error Error
  end

  it "#change_admin_password" do
    lambda { @cli.change_admin_password('admin@example.com', 'new_password') }.should_not raise_error
    Admin.find('admin@example.com').password.should == CRAM_MD5_NEW_PASS
    lambda { @cli.change_admin_password('unknown_admin@example.com', 'new_password') }.should raise_error Error

    lambda { @cli.change_admin_password('admin@example.com', '1234') }.should raise_error ArgumentError
  end

  it "#change_account_password" do
    lambda { @cli.change_account_password('user@example.com', 'new_password') }.should_not raise_error
    Mailbox.find('user@example.com').password.should == CRAM_MD5_NEW_PASS
    lambda { @cli.change_account_password('unknown@example.com', 'new_password') }.should raise_error Error
    lambda { @cli.change_account_password('user@example.com', '1234') }.should raise_error ArgumentError
  end

  describe "#add_admin" do
    it "can add a new admin" do
      lambda { @cli.add_admin('new_admin@example.com', 'password') }.should_not raise_error
      Admin.exist?('new_admin@example.com').should be true
    end

    it "can not add exist admin" do
      lambda { @cli.add_admin('admin@example.com', 'password') }.should raise_error Error
    end

    it "does not allow too short password (<5)" do
      lambda { @cli.add_admin('admin@example.com', '1234') }.should raise_error ArgumentError
    end
  end

  describe "#delete_admin" do
    it "can delete an admin" do
      lambda { @cli.delete_admin('admin@example.com') }.should_not raise_error
      Admin.exist?('admin@example.com').should be false
    end

    it "can delete a super admin" do
      lambda { @cli.delete_admin('all@example.com') }.should_not raise_error
      Admin.exist?('all@example.com').should be false
    end

    it "can delete an admin whish has multiple domains" do
      @cli.add_admin_domain('admin@example.com', 'example.org')
      lambda { @cli.delete_admin('admin@example.com') }.should_not raise_error
      Admin.exist?('admin@example.com').should be false
    end

    it "can not delete unknown admin" do
      lambda { @cli.delete_admin('unknown_admin@example.com') }.should raise_error Error
    end
  end

  it "#add_alias and #delete_alias" do
    lambda { @cli.add_alias('user@example.com', 'goto@example.jp') }.should raise_error Error
    lambda { @cli.delete_alias('user@example.com') }.should raise_error Error
    lambda { @cli.delete_alias('unknown@example.com') }.should raise_error Error

    lambda { @cli.add_alias('new_alias@example.com', 'goto@example.jp') }.should_not raise_error
    Alias.exist?('new_alias@example.com').should be true

    lambda { @cli.delete_alias('new_alias@example.com') }.should_not raise_error
    Alias.exist?('new_alias@example.com').should be false
  end

  describe "#add_account" do
    it "can add an account" do
      lambda { @cli.add_account('new_user@example.com', 'password') }.should_not raise_error
      Mailbox.exist?('new_user@example.com').should be true
      Alias.exist?('new_user@example.com').should be true
    end

    it "can not add account of unknown domain" do
      lambda { @cli.add_account('user@unknown.example.com', 'password') }.should raise_error Error
    end

    it "does not allow too short password (<5)" do
      lambda { @cli.add_account('new_user@example.com', '1234') }.should raise_error ArgumentError
    end
  end

  describe "#delete_accont" do
    it "can delete an account" do
      lambda { @cli.delete_account('user@example.com') }.should_not raise_error
      Mailbox.exist?('user@example.com').should be false
      Alias.exist?('user@example.com').should be false
    end

    it "can not delete unknown account" do
      lambda { @cli.delete_account('unknown@example.com') }.should raise_error Error
    end
  end

  describe "#add_domain" do
    it "can add a new domain" do
      lambda { @cli.add_domain('example.net') }.should_not raise_error
    end

    it "upcase will convert to downcase" do
      lambda{ @cli.add_domain('ExAmPle.NeT') }.should_not raise_error
      Domain.exist?('example.net').should be true
    end

    it "can not add exist domain" do
      lambda{ @cli.add_domain('example.com') }.should raise_error Error
      lambda{ @cli.add_domain('ExAmPle.Com') }.should raise_error Error
    end
  end

  describe "#edit_domain" do
    it "can update domain limitations" do
      lambda{ @cli.edit_domain('example.com', {aliases: 40, mailboxes: 40, maxquota: 400, active: false}) }.should_not raise_error
      domain = Domain.find('example.com')
      domain.maxaliases.should == 40
      domain.maxmailboxes.should == 40
      domain.maxquota.should == 400
      expect(domain.active).to be false
    end
  end

  describe "#edit_account" do
    it "can update account" do
      lambda { @cli.edit_account('user@example.com', {quota: 50, active: false}) }.should_not raise_error
      mailbox = Mailbox.find('user@example.com')
      mailbox.quota.should == 50 * KB_TO_MB
      expect(mailbox.active).to be false
    end

    it "raise error when unknown account" do
      lambda { @cli.edit_account('unknown@example.com', {:quota => 50}) }.should raise_error Error
    end
  end

  describe "#edit_admin" do
    it "can update admin" do
      expect { @cli.edit_admin('admin@example.com', {super: true, active: false}) }.not_to raise_error
      admin = Admin.find('admin@example.com')
      expect(admin.super_admin?).to be true
      expect(admin.active).to be false
    end
  end

  describe "#delete_domain" do
    it "can delete exist domain" do
      lambda { @cli.delete_domain('example.com') }.should_not raise_error
      Domain.exist?('example.net').should be false
    end

    it "upcase will convert to downcase" do
      lambda { @cli.delete_domain('eXaMplE.cOm') }.should_not raise_error
      Domain.exist?('example.com').should be false
    end

    it "can delete related admins, addresses and aliases" do
      @cli.add_admin('admin@example.org', 'password')
      @cli.add_admin_domain('admin@example.org', 'example.org')
      @cli.add_account('user2@example.com', 'password')

      @cli.add_admin('other_admin@example.com', 'password')
      @cli.add_admin_domain('other_admin@example.com', 'example.com')

      @cli.add_admin('no_related@example.com', 'password')

      lambda { @cli.delete_domain('example.com') }.should_not raise_error
      Admin.exist?('admin@example.com').should be false
      Admin.exist?('admin@example.org').should be true
      Admin.exist?('other_admin@example.com').should be false
      Admin.exist?('no_related@example.com').should be true

      # aliases should be removed
      Alias.exist?('alias@example.com').should be false
      Alias.exist?('user@example.com').should be false
      Alias.exist?('user2@example.com').should be false

      # mailboxes should be removed
      Mailbox.exist?('user@example.com').should be false
      Mailbox.exist?('user2@example.com').should be false
    end
  end

  describe "#dump" do
    it do
      lambda { @cli.dump }.should_not raise_error
    end

    it "print infomation of all domains" do
      result = capture(:stdout){ @cli.dump }
      result.should =~ /example.com,100,true/
      result.should =~ /example.org,100,true/
      result.should =~ /admin@example.com,"9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740",false,true/
      result.should =~ /user@example.com,"","9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740",102400000,"example.com\/user@example.com\/",true/
      result.should =~ /alias@example.com,"goto@example.jp",true/
      result.should =~ /user@example.com,"goto@example.jp",true/
    end
  end
end
