require 'active_record'
require 'postfix_admin/concerns/existing_timestamp'

module PostfixAdmin
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    include ExistingTimestamp

    RE_DOMAIN_NAME_LIKE_BASE = '([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}'
    RE_EMAIL_LIKE_BASE = '[^@\s]+@([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}'

    RE_DOMAIN_NAME_LIKE = /#{RE_DOMAIN_NAME_LIKE_BASE}/
    RE_EMAIL_LIKE = /#{RE_EMAIL_LIKE_BASE}/

    RE_DOMAIN_NAME_LIKE_WITH_ANCHORS = /\A#{RE_DOMAIN_NAME_LIKE_BASE}\z/
    RE_EMAIL_LIKE_WITH_ANCHORS = /\A#{RE_EMAIL_LIKE_BASE}\z/

    scope :active, -> { where(active: true) }

    def inactive?
      !active?
    end

    def active_str
      active? ? "Active" : "Inactive"
    end
  end
end
