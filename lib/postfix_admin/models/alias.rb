require "postfix_admin/models/application_record"

module PostfixAdmin
  class Alias < ApplicationRecord
    # version: 1841
    # > describe alias;
    # +----------+--------------+------+-----+---------------------+-------+
    # | Field    | Type         | Null | Key | Default             | Extra |
    # +----------+--------------+------+-----+---------------------+-------+
    # | address  | varchar(255) | NO   | PRI | NULL                |       |
    # | goto     | text         | NO   |     | NULL                |       |
    # | domain   | varchar(255) | NO   | MUL | NULL                |       |
    # | created  | datetime     | NO   |     | 2000-01-01 00:00:00 |       |
    # | modified | datetime     | NO   |     | 2000-01-01 00:00:00 |       |
    # | active   | tinyint(1)   | NO   |     | 1                   |       |
    # +----------+--------------+------+-----+---------------------+-------+

    self.table_name = :alias
    self.primary_key = :address

    validate on: :create do |a|
      domain = a.rel_domain

      if domain.alias_unlimited?
        # unlimited: do nothing
      elsif domain.alias_disabled?
        # disabled
        a.errors.add(:domain, "has a disabled status for aliases")
      elsif domain.pure_alias_count >= domain.aliases
        # exceeding alias limit
        message = "has already reached the maximum number of aliases " \
          "(maximum: #{domain.aliases})"
        a.errors.add(:domain, message)
      end
    end

    validates :address, presence: true, uniqueness: { case_sensitive: false },
                        format: { with: RE_EMAIL_LIKE_WITH_ANCHORS,
                                  message: "must be a valid email address" }
    validates :goto, presence: true

    belongs_to :rel_domain, class_name: "Domain", foreign_key: :domain
    belongs_to :mailbox, foreign_key: :address, optional: true

    # aliases which do not belong to any mailbox
    scope :pure, -> { joins("LEFT OUTER JOIN mailbox ON alias.address = mailbox.username").where("mailbox.username" => nil) }

    # aliases which belong to a mailbox and have forwardings to other addresses
    scope :forward, -> { joins("LEFT OUTER JOIN mailbox ON alias.address = mailbox.username").where("mailbox.username <> alias.goto") }

    def mailbox?
      !!mailbox
    end

    def pure_alias?
      !mailbox
    end

    def gotos
      goto.split(",")
    end
  end
end