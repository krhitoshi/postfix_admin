require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/doveadm'

describe PostfixAdmin::Doveadm do
  describe "schemes" do
    it "return Array" do
      PostfixAdmin::Doveadm.schemes.class.should == Array
    end

    it "return supported schemes" do
      PostfixAdmin::Doveadm.schemes.should == %W!CRYPT MD5 MD5-CRYPT SHA SHA1 SHA256 SHA512 SMD5 SSHA SSHA256 SSHA512 PLAIN CLEARTEXT PLAIN-TRUNC CRAM-MD5 HMAC-MD5 DIGEST-MD5 PLAIN-MD4 PLAIN-MD5 LDAP-MD5 LANMAN NTLM OTP SKEY RPA!
    end
  end

  describe "password" do
    it "CRAM-MD5" do
      PostfixAdmin::Doveadm.password('password', 'CRAM-MD5').should == '9186d855e11eba527a7a52ca82b313e180d62234f0acc9051b527243d41e2740'
      PostfixAdmin::Doveadm.password('dovecot', 'CRAM-MD5').should == '2dc40f88a4c2142c3b10cc4b4d11382a648f600301b78a4070172782192898d6'
    end

    it "SHA256" do
      PostfixAdmin::Doveadm.password('password', 'SHA256').should == 'XohImNooBHFR0OVvjcYpJ3NgPQ1qq73WKhHvch0VQtg='
      PostfixAdmin::Doveadm.password('dovecot', 'SHA256').should == 'KN7aHmDsiQ/Ko+HzLzHcKoPqkjk7bditnD433YQYhcs='
    end

    it "MD5-CRYPT" do
      PostfixAdmin::Doveadm.password('password', 'MD5-CRYPT').should =~ EX_MD5_CRYPT
      PostfixAdmin::Doveadm.password('dovecot', 'MD5-CRYPT').should =~ EX_MD5_CRYPT
    end

    it "unknown scheme raise error" do
      lambda{ PostfixAdmin::Doveadm.password('password', 'UNKNOWN-SCHEME') }.should raise_error Error
    end
  end
end
