require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/base'

RSpec.describe PostfixAdmin::Base do
  before do
    db_initialize
    @base = Base.new({'database' => 'mysql2://postfix:password@localhost/postfix'})
  end

  it "DEFAULT_CONFIG" do
    res = {
        'database'  => 'mysql2://postfix:password@localhost/postfix',
        'aliases'   => 30,
        'mailboxes' => 30,
        'maxquota'  => 100,
        'scheme'    => 'CRAM-MD5',
        'passwordhash_prefix' => true
    }
    expect(Base::DEFAULT_CONFIG).to eq res
  end

  it "#address_split" do
    expect(@base.address_split('user@example.com')).to eq ['user', 'example.com']
  end

  it "#new without config" do
    expect { Base.new }.to raise_error ArgumentError
  end

  it "Default configuration to be correct" do
    expect(@base.config[:aliases]).to eq 30
    expect(@base.config[:mailboxes]).to eq 30
    expect(@base.config[:maxquota]).to eq 100
    expect(@base.config[:scheme]).to eq 'CRAM-MD5'
  end

  it "config database" do
    expect(@base.config[:database]).to eq 'mysql2://postfix:password@localhost/postfix'
  end

  it "#domain_exists?" do
    expect(Domain.exists?('example.com')).to be true
  end

  it "#alias_exists?" do
    expect(Alias.exists?('user@example.com')).to be true
    expect(Alias.exists?('unknown@example.com')).to be false
  end

  it "#mailbox_exists?" do
    expect(Mailbox.exists?('user@example.com')).to be true
    expect(Mailbox.exists?('unknown@example.com')).to be false
  end

  it "#admin_exists?" do
    expect(Admin.exists?('admin@example.com')).to be true
    expect(Admin.exists?('unknown_admin@example.com')).to be false
  end

  describe "#add_domain" do
    it "can add a new domain" do
      num_domains = Domain.count
      @base.add_domain('example.net')
      expect(Domain.count - num_domains).to eq 1
    end

    it "can not add exist domain" do
      expect { @base.add_domain('example.com') }.to raise_error Error
    end

    it "can not add invalid domain" do
      expect { @base.add_domain('localhost') }.to raise_error Error
    end
  end

  describe "#add_account" do
    it "can add a new account" do
      num_mailboxes = Mailbox.count
      num_aliases   = Alias.count
      @base.add_account('new_user@example.com', 'password')
      expect(Mailbox.count - num_mailboxes).to eq 1
      expect(Alias.count - num_aliases).to eq 1
    end

    it "refuse empty password" do
      expect { @base.add_account('new_user@example.com', '') }.to raise_error Error
    end

    it "refuse nil password" do
      expect { @base.add_account('new_user@example.com', nil) }.to raise_error Error
    end

    it "can not add account which hsas invalid address" do
      expect { @base.add_account('invalid.example.com', 'password') }.to raise_error Error
    end

    it "can not add account for unknown domain" do
      expect { @base.add_account('user@unknown.example.com', 'password') }.to raise_error Error
    end

    it "can not add account which has same address as exist mailbox" do
      expect { @base.add_account('user@example.com', 'password') }.to raise_error Error
    end

    it "can not add account which has same address as exist alias" do
      expect { @base.add_account('alias@example.com', 'password') }.to raise_error Error
    end
  end

  describe "#add_admin" do
    it "can add an new admin" do
      num_admins = Admin.count
      @base.add_admin('admin@example.net', 'password')
      expect(Admin.exists?('admin@example.net')).to be true
      expect(Admin.count - num_admins).to eq 1
    end

    it "refuse empty password" do
      expect { @base.add_admin('admin@example.net', '') }.to raise_error Error
    end

    it "refuse nil password" do
      expect { @base.add_admin('admin@example.net', nil) }.to raise_error Error
    end

    it "can not add exist admin" do
      expect { @base.add_admin('admin@example.com', 'password') }.to raise_error Error
    end
  end

  describe "#add_admin_domain" do
    it "#add_admin_domain" do
      @base.add_admin_domain('admin@example.com', 'example.org')
      d = Domain.find('example.org')
      expect(Admin.find('admin@example.com').has_domain?(d)).to be true
    end

    it "can not add unknown domain for an admin" do
      expect { @base.add_admin_domain('admin@example.com', 'unknown.example.com') }.to raise_error Error
    end

    it "can not add domain for unknown admin" do
      expect { @base.add_admin_domain('unknown_admin@example.com', 'example.net') }.to raise_error Error
    end

    it "can not add a domain which the admin has already privileges for" do
      expect { @base.add_admin_domain('admin@example.com', 'example.com') }.to raise_error Error
    end
  end

  describe "#delete_admin_domain" do
    it "#delete_admin_domain" do
      d = Domain.find('example.org')
      expect { @base.delete_admin_domain('admin@example.com', 'example.com') }.to_not raise_error
      expect(Admin.find('admin@example.com').has_domain?(d)).to be false
    end

    it "can not delete not administrated domain" do
      expect { @base.delete_admin_domain('admin@example.com', 'example.org') }.to raise_error Error
    end

    it "raise error when unknown admin" do
      expect { @base.delete_admin_domain('unknown_admin@example.com', 'example.com') }.to raise_error Error
    end

    it "raise error when unknown domain" do
      expect { @base.delete_admin_domain('admin@example.com', 'unknown.example.com') }.to raise_error Error
    end
  end

  describe "#add_alias" do
    it "can add a new alias" do
      num_aliases = Alias.count
      expect { @base.add_alias('new_alias@example.com', 'goto@example.jp') }.to_not raise_error
      expect(Alias.count - num_aliases).to eq 1
      expect(Alias.exists?('new_alias@example.com')).to be true
    end

    it "can not add an alias which has a same name as a mailbox" do
      expect { @base.add_alias('user@example.com', 'goto@example.jp') }.to raise_error Error
    end

    it "can not add an alias which has a sama name as other alias" do
      @base.add_alias('new_alias@example.com', 'goto@example.jp')
      expect { @base.add_alias('new_alias@example.com', 'goto@example.jp') }.to raise_error Error
    end

    it "can not add an alias of unknown domain" do
      expect { @base.add_alias('new_alias@unknown.example.com', 'goto@example.jp') }.to raise_error Error
    end
  end

  describe "#delete_alias" do
    it "can delete an alias" do
      expect { @base.delete_alias('alias@example.com') }.to_not raise_error
      expect(Alias.exists?('alias@example.com')).to be false
    end

    it "can not delete mailbox" do
      expect { @base.delete_alias('user@example.com') }.to raise_error Error
    end

    it "can not delete unknown alias" do
      expect { @base.delete_alias('unknown@example.com') }.to raise_error Error
    end
  end

  describe "#delete_domain" do
    before do
      @base.add_account('user2@example.com', 'password')
      @base.add_account('user3@example.com', 'password')

      @base.add_alias('alias2@example.com', 'goto2@example.jp')
      @base.add_alias('alias3@example.com', 'goto3@example.jp')
    end

    it "can delete a domain" do
      expect { @base.delete_domain('example.com') }.to_not raise_error

      expect(Domain.exists?('example.com')).to be false
      expect(Admin.exists?('admin@example.com')).to be false

      expect(Alias.where(domain: 'example.com').count).to eq 0
      expect(Mailbox.where(domain: 'example.com').count).to eq 0

      expect(DomainAdmin.where(username: 'admin@example.com',
                        domain: 'example.com').count).to eq 0
    end

    it "can not delete unknown domain" do
      expect { @base.delete_domain('unknown.example.com') }.to raise_error Error
    end
  end

  describe "#delete_admin" do
    it "can delete an admin" do
      expect { @base.delete_admin('admin@example.com') }.to_not raise_error
      expect(Admin.exists?('admin@example.com')).to be false
    end

    it "can not delete unknown admin" do
      expect { @base.delete_admin('unknown_admin@example.com') }.to raise_error Error
    end
  end

  describe "#delete_account" do
    it "can delete an account" do
      expect { @base.delete_account('user@example.com') }.to_not raise_error
      expect(Mailbox.exists?('user@example.com')).to be false
      expect(Alias.exists?('user@example.com')).to be false
    end

    it "can not delete unknown account" do
      expect { @base.delete_account('unknown@example.com') }.to raise_error Error
    end
  end
end
