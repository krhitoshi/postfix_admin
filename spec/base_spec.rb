require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/base'

RSpec.describe PostfixAdmin::Base do
  before do
    db_initialize
    @base = Base.new({'database' => 'mysql2://postfix:password@localhost/postfix'})
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

  describe "#delete_admin" do
    it "can delete an admin" do
      expect { @base.delete_admin('admin@example.com') }.to_not raise_error
      expect(Admin.exists?('admin@example.com')).to be false
    end

    it "can not delete unknown admin" do
      expect { @base.delete_admin('unknown_admin@example.com') }.to raise_error Error
    end
  end
end
