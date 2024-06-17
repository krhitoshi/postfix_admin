module PostfixAdmin
  class Mailbox < ApplicationRecord
    self.table_name = :mailbox
    self.primary_key = :username

    include DovecotCramMD5Password

    attribute :quota_mb, :integer

    validates :username, presence: true, uniqueness: { case_sensitive: false },
                         format: { with: RE_EMAIL_LIKE_WITH_ANCHORS,
                                   message: "must be a valid email address" }
    validates :maildir, presence: true, uniqueness: { case_sensitive: false }
    validates :local_part, presence: true

    # quota (KB)
    validates :quota, presence: true,
                      numericality: { only_integer: true,
                                      greater_than_or_equal_to: 0 }

    # quota (MB), which actually doesn't exist in DB
    validates :quota_mb, presence: true,
                         numericality: { only_integer: true,
                                         greater_than_or_equal_to: 0 }

    belongs_to :rel_domain, class_name: "Domain", foreign_key: :domain
    has_one :alias, foreign_key: :address, dependent: :destroy
    has_one :quota_usage, class_name: "Quota", foreign_key: :username,
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
      domain = mailbox.rel_domain

      unless domain.maxquota.zero?
        if mailbox.quota_mb.zero?
          mailbox.errors.add(:quota_mb, "cannot be 0")
        elsif mailbox.quota_mb > domain.maxquota
          message = "must be less than or equal to #{domain.maxquota} (MB)"
          mailbox.errors.add(:quota_mb, message)
        end
      end
    end

    before_validation do |mailbox|
      mailbox.name = "" if mailbox.name.nil?
      if mailbox.quota_mb
        mailbox.quota = mailbox.quota_mb * KB_TO_MB
      elsif mailbox.quota
        mailbox.quota_mb = mailbox.quota / KB_TO_MB
      else
        mailbox.quota_mb = 0
        mailbox.quota = 0
      end
      mailbox.username = "#{mailbox.local_part}@#{mailbox.domain}"
      mailbox.maildir ||= "#{mailbox.domain}/#{mailbox.username}/"
      mailbox.build_alias(local_part: mailbox.local_part, goto: mailbox.username,
                          domain: mailbox.domain)
    end

    # example: {CRAM-MD5}, {BLF-CRYPT}, {PLAIN}
    # return nil if no scheme prefix
    def scheme_prefix
      res = password&.match(/^\{.*?\}/)
      if res
        res[0]
      else
        nil
      end
    end

    def quota_usage_str
      if quota_usage
        usage_mb = quota_usage.bytes / KB_TO_MB
        usage_mb.to_s
      else
        "0"
      end
    end

    def quota_mb_str
      case quota
      when -1
        # It's not sure what 'disabled' means for quota.
        "Disabled"
      when 0
        "Unlimited"
      else
        mb_size = quota / KB_TO_MB
        mb_size.to_s
      end
    end
  end
end