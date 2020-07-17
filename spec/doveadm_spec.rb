require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'postfix_admin/doveadm'

RSpec.describe PostfixAdmin::Doveadm do
  describe "schemes" do
    it "return Array" do
      expect(Doveadm.schemes).to be_an_instance_of(Array)
    end

    it "return supported schemes" do
      expect(Doveadm.schemes.include?("PLAIN")).to be true
      expect(Doveadm.schemes.include?("CRAM-MD5")).to be true
    end
  end

  describe "password" do
    context "with prefix" do
      it "CRAM-MD5" do
        expect(Doveadm.password('password', 'CRAM-MD5', true)).to \
          eq CRAM_MD5_PASS
        expect(Doveadm.password('dovecot', 'CRAM-MD5', true)).to \
          eq '{CRAM-MD5}2dc40f88a4c2142c3b10cc4b4d11382a648f600301b78a4070172782192898d6'
      end

      it "SHA256" do
        expect(Doveadm.password('password', 'SHA256', true)).to \
          eq '{SHA256}XohImNooBHFR0OVvjcYpJ3NgPQ1qq73WKhHvch0VQtg='
        expect(Doveadm.password('dovecot', 'SHA256', true)).to \
          eq '{SHA256}KN7aHmDsiQ/Ko+HzLzHcKoPqkjk7bditnD433YQYhcs='
      end

      it "MD5-CRYPT" do
        expect(Doveadm.password('password', 'MD5-CRYPT', true)).to \
          match EX_MD5_CRYPT
        expect(Doveadm.password('dovecot', 'MD5-CRYPT', true)).to \
          match EX_MD5_CRYPT
      end

      it "unknown scheme raise error" do
        expect { Doveadm.password('password', 'UNKNOWN-SCHEME', true) }.to \
          raise_error Error
      end
    end

    context "without prefix" do
      it "CRAM-MD5 without prefix" do
        expect(Doveadm.password('password', 'CRAM-MD5', false)).to \
          eq CRAM_MD5_PASS_WITHOUT_PREFIX
        expect(Doveadm.password('dovecot', 'CRAM-MD5', false)).to \
          eq '2dc40f88a4c2142c3b10cc4b4d11382a648f600301b78a4070172782192898d6'
      end

      it "SHA256 without prefix" do
        expect(Doveadm.password('password', 'SHA256', false)).to \
          eq 'XohImNooBHFR0OVvjcYpJ3NgPQ1qq73WKhHvch0VQtg='
        expect(Doveadm.password('dovecot', 'SHA256', false)).to \
          eq 'KN7aHmDsiQ/Ko+HzLzHcKoPqkjk7bditnD433YQYhcs='
      end

      it "MD5-CRYPT without prefix" do
        expect(Doveadm.password('password', 'MD5-CRYPT', false)).to \
          match EX_MD5_CRYPT_WITHOUT_PREFIX
        expect(Doveadm.password('dovecot', 'MD5-CRYPT', false)).to \
          match EX_MD5_CRYPT_WITHOUT_PREFIX
      end
    end
  end
end
