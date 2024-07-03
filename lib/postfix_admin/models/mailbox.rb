require 'postfix_admin/models/concerns/has_password'

module PostfixAdmin
  class Mailbox < ApplicationRecord
    # version: 1841
    # > describe mailbox;
    # +----------------+--------------+------+-----+---------------------+-------+
    # | Field          | Type         | Null | Key | Default             | Extra |
    # +----------------+--------------+------+-----+---------------------+-------+
    # | username       | varchar(255) | NO   | PRI | NULL                |       |
    # | password       | varchar(255) | NO   |     | NULL                |       |
    # | name           | varchar(255) | NO   |     | NULL                |       |
    # | maildir        | varchar(255) | NO   |     | NULL                |       |
    # | quota          | bigint(20)   | NO   |     | 0                   |       |
    # | local_part     | varchar(255) | NO   |     | NULL                |       |
    # | domain         | varchar(255) | NO   | MUL | NULL                |       |
    # | created        | datetime     | NO   |     | 2000-01-01 00:00:00 |       |
    # | modified       | datetime     | NO   |     | 2000-01-01 00:00:00 |       |
    # | active         | tinyint(1)   | NO   |     | 1                   |       |
    # | phone          | varchar(30)  | NO   |     |                     |       |
    # | email_other    | varchar(255) | NO   |     |                     |       |
    # | token          | varchar(255) | NO   |     |                     |       |
    # | token_validity | datetime     | NO   |     | 2000-01-01 00:00:00 |       |
    # +----------------+--------------+------+-----+---------------------+-------+

    self.table_name = :mailbox
    self.primary_key = :username

    include HasPassword

    # attribute :quota_mb, :integer

    validates :username, presence: true, uniqueness: { case_sensitive: false },
                         format: { with: RE_EMAIL_LIKE_WITH_ANCHORS,
                                   message: "must be a valid email address" }
    validates :maildir, presence: true, uniqueness: { case_sensitive: false }
    validates :local_part, presence: true

    # quota (KB)
    validates :quota, presence: true,
                      numericality: { only_integer: true,
                                      greater_than_or_equal_to: 0 }

    belongs_to :rel_domain, class_name: "Domain", foreign_key: :domain
    has_one :alias, foreign_key: :address, dependent: :destroy
    has_one :quota_usage, class_name: "Quota2", foreign_key: :username,
            dependent: :destroy

    validate on: :create do |mailbox|
      domain = mailbox.rel_domain
      if !domain.mailboxes.zero? && domain.rel_mailboxes.count >= domain.mailboxes
        message = "already has the maximum number of mailboxes " \
                  "(maximum is #{domain.mailboxes} mailboxes)"
        mailbox.errors.add(:domain, message)
      end
    end

    # just in case
    validate on: :update do |mailbox|
      mailbox.errors.add(:username, 'cannot be changed') if mailbox.username_changed?
      mailbox.errors.add(:local_part, 'cannot be changed') if mailbox.local_part_changed?
    end

    validate do |mailbox|
      next if mailbox.quota == -1

      domain = mailbox.rel_domain

      unless domain.maxquota.zero?
        if mailbox.quota.zero?
          mailbox.errors.add(:quota, "cannot be 0")
        elsif mailbox.quota_mb > domain.maxquota
          message = "must be less than or equal to #{domain.maxquota} (MB)"
          mailbox.errors.add(:quota, message)
        end
      end
    end

    before_validation do |mailbox|
      mailbox.name = "" if mailbox.name.nil?
      mailbox.username = "#{mailbox.local_part}@#{mailbox.domain}"
      mailbox.maildir ||= "#{mailbox.domain}/#{mailbox.username}/"
      mailbox.build_alias(address: mailbox.username, goto: mailbox.username,
                          domain: mailbox.domain)
    end

    def quota_mb
      raise Error, "quota is out of range: #{quota}" if quota < 0

      quota / KB_TO_MB
    end

    def quota_mb=(value)
      raise Error, "quota is out of range: #{value}" if value < 0

      self.quota = value * KB_TO_MB
    end

    def quota_usage_str(format: "%6.1f")
      usage_mb = if quota_usage
                   usage_mb = quota_usage.bytes / KB_TO_MB.to_f
                 else
                   0.0
                 end

      format % usage_mb
    end

    def quota_mb_str(format: "%6.1f")
      case quota
      when -1
        # It's not sure what 'disabled' means for quota.
        "Disabled"
      when 0
        "Unlimited"
      else
        quota_mb = quota / KB_TO_MB.to_f
        format % quota_mb
      end
    end

    def quota_display_str(format: "%6.1f")
      "%s / %s" % [quota_usage_str(format: format), quota_mb_str(format: format)]
    end
  end
end