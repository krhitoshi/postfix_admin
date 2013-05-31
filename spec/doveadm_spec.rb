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
end
