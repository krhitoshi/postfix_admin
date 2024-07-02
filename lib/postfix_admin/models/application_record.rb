require 'active_record'
require 'postfix_admin/models/concerns/existing_timestamp'

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

    # This is a workaround to set current time to timestamp columns when a record is created.
    # Activerecord does not insert timestamps if default values are set for the columns.
    before_create :set_current_time_to_timestamp_columns, if: :has_timestamp_columns?

    def set_current_time_to_timestamp_columns
      now = Time.now
      self.created = now
      self.modified = now
    end

    def has_timestamp_columns?
      column_names = self.class.column_names
      column_names.include?("created") && column_names.include?("modified")
    end
  end
end
