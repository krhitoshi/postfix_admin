require 'active_support/concern'

module DovecotCramMD5Password
  extend ActiveSupport::Concern

  included do
    validates :password_unencrypted, length: { minimum: 5 }, allow_blank: true
    validates_confirmation_of :password_unencrypted, allow_blank: true

    validate do |record|
      record.errors.add(:password_unencrypted, :blank) unless record.password.present?
    end

    attr_reader :password_unencrypted
    attr_accessor :password_unencrypted_confirmation
  end

  def password_unencrypted=(unencrypted_password)
    if unencrypted_password.nil?
      self.password = nil
    elsif !unencrypted_password.empty?
      @password_unencrypted = unencrypted_password
      self.password = DovecotCrammd5.calc(unencrypted_password)
    end
  end

  def authenticate(unencrypted_password)
    password == DovecotCrammd5.calc(unencrypted_password) && self
  end
end
