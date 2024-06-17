require 'postfix_admin/concerns/dovecot_cram_md5_password'

module PostfixAdmin
  class Admin < ApplicationRecord
    self.table_name = :admin
    self.primary_key = :username

    include DovecotCramMD5Password

    validates :username, presence: true, uniqueness: { case_sensitive: false },
                         format: { with: RE_EMAIL_LIKE_WITH_ANCHORS,
                                   message: "must be a valid email address" }

    has_many :domain_admins, foreign_key: :username, dependent: :delete_all
    has_many :rel_domains, through: :domain_admins

    attr_accessor :domain_ids
    attribute :form_super_admin, :boolean, default: false

    # just in case
    validate on: :update do |admin|
      admin.errors.add(:username, 'cannot be changed') if admin.username_changed?
    end

    def reload
      @super_admin = nil
      super
    end

    def super_admin?
      if @super_admin.nil?
        @super_admin = if has_superadmin_column?
          self.superadmin && rel_domains.exists?("ALL")
        else
          rel_domains.exists?("ALL")
        end
      else
        @super_admin
      end
    end

    def super_admin=(value)
      if value
        domain_ids = self.rel_domain_ids.dup
        domain_ids << "ALL"
        self.rel_domain_ids = domain_ids
        self.superadmin = true if has_superadmin_column?
      else
        domain_admins.where(domain: "ALL").delete_all
        self.superadmin = false if has_superadmin_column?
      end
      save!
    end

    def has_superadmin_column?
      has_attribute?(:superadmin)
    end

    def has_admin?(admin)
      self == admin || super_admin?
    end

    def has_domain?(domain)
      !rel_domains.where(domain: ["ALL", domain.domain]).empty?
    end

    def scheme_prefix
      res = password&.match(/^\{.*?\}/)
      if res
        res[0]
      else
        nil
      end
    end
  end
end