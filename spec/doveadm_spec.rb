require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/doveadm'

describe PostfixAdmin::Doveadm do
  describe "schemes" do
    it "return Array" do
      PostfixAdmin::Doveadm.schemes.class.should == Array
    end

    it "return supported schemes" do
      PostfixAdmin::Doveadm.schemes.include?("CRAM-MD5").should == true
    end
  end

  describe "password" do
    it "CRAM-MD5" do
      PostfixAdmin::Doveadm.password('password', 'CRAM-MD5').should == CRAM_MD5_PASS
      PostfixAdmin::Doveadm.password('dovecot', 'CRAM-MD5').should == '{CRAM-MD5}2dc40f88a4c2142c3b10cc4b4d11382a648f600301b78a4070172782192898d6'
    end

    it "SHA256" do
      PostfixAdmin::Doveadm.password('password', 'SHA256').should == '{SHA256}XohImNooBHFR0OVvjcYpJ3NgPQ1qq73WKhHvch0VQtg='
      PostfixAdmin::Doveadm.password('dovecot', 'SHA256').should == '{SHA256}KN7aHmDsiQ/Ko+HzLzHcKoPqkjk7bditnD433YQYhcs='
    end

    it "MD5-CRYPT" do
      PostfixAdmin::Doveadm.password('password', 'MD5-CRYPT').should =~ EX_MD5_CRYPT
      PostfixAdmin::Doveadm.password('dovecot', 'MD5-CRYPT').should =~ EX_MD5_CRYPT
    end

    it "unknown scheme raise error" do
      lambda { PostfixAdmin::Doveadm.password('password', 'UNKNOWN-SCHEME') }.should raise_error Error
    end
  end
end
