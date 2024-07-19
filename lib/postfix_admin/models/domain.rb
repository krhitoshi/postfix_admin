require "postfix_admin/models/application_record"

module PostfixAdmin
  class Domain < ApplicationRecord
    # version: 1841
    # > describe domain;
    # +-------------+--------------+------+-----+---------------------+-------+
    # | Field       | Type         | Null | Key | Default             | Extra |
    # +-------------+--------------+------+-----+---------------------+-------+
    # | domain      | varchar(255) | NO   | PRI | NULL                |       |
    # | description | varchar(255) | NO   |     | NULL                |       |
    # | aliases     | int(10)      | NO   |     | 0                   |       |
    # | mailboxes   | int(10)      | NO   |     | 0                   |       |
    # | maxquota    | bigint(20)   | NO   |     | 0                   |       |
    # | quota       | bigint(20)   | NO   |     | 0                   |       |
    # | transport   | varchar(255) | NO   |     | NULL                |       |
    # | backupmx    | tinyint(1)   | NO   |     | 0                   |       |
    # | created     | datetime     | NO   |     | 2000-01-01 00:00:00 |       |
    # | modified    | datetime     | NO   |     | 2000-01-01 00:00:00 |       |
    # | active      | tinyint(1)   | NO   |     | 1                   |       |
    # +-------------+--------------+------+-----+---------------------+-------+

    UNLIMITED = 0
    DISABLED  = -1

    self.table_name = :domain
    self.primary_key = :domain

    validates :domain, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: RE_DOMAIN_NAME_LIKE_WITH_ANCHORS,
                                 message: "must be a valid domain name" }
    validates :transport, presence: true

    # max aliases (Disabled: -1, Unlimited: 0)
    validates :aliases, presence: true,
                        numericality: { only_integer: true,
                                        greater_than_or_equal_to: -1 }
    # max mailboxes (Disabled: -1, Unlimited: 0)
    validates :mailboxes, presence: true,
                          numericality: { only_integer: true,
                                          greater_than_or_equal_to: -1 }

    # max quota (MB) for each mailbox (Unlimited: 0)
    # It's not sure what 'disabled' means for max quota.
    # So it's better not to allow users to set `maxquota` to -1.
    validates :maxquota, presence: true,
                         numericality: { only_integer: true,
                                         greater_than_or_equal_to: 0 }

    # mailboxes that belong to this domain
    has_many :rel_mailboxes, class_name: "Mailbox", foreign_key: :domain,
                             dependent: :destroy
    # aliases that belong to this domain
    has_many :rel_aliases, class_name: "Alias", foreign_key: :domain,
                           dependent: :destroy

    # logs that belong to this domain
    has_many :logs, class_name: "Log", foreign_key: :domain,
             dependent: :destroy

    # It causes errors to set `dependent: :destroy` as other columns
    # because the domain_admins table doesn't have a single primary key.
    #
    # PostfixAdmin::DomainAdmin Load (0.5ms)  SELECT `domain_admins`.* FROM `domain_admins` WHERE `domain_admins`.`domain` = 'example.com'
    # PostfixAdmin::DomainAdmin Destroy (1.1ms)  DELETE FROM `domain_admins` WHERE `domain_admins`.`` IS NULL
    #
    # ActiveRecord::StatementInvalid: Mysql2::Error: Unknown column 'domain_admins.' in 'where clause'
    # from /usr/local/bundle/gems/mysql2-0.5.4/lib/mysql2/client.rb:148:in `_query'
    # Caused by Mysql2::Error: Unknown column 'domain_admins.' in 'where clause'
    # from /usr/local/bundle/gems/mysql2-0.5.4/lib/mysql2/client.rb:148:in `_query'
    #
    # It works well with `dependent: :delete_all` instead.
    #
    # PostfixAdmin::DomainAdmin Destroy (0.4ms)  DELETE FROM `domain_admins` WHERE `domain_admins`.`domain` = 'example.com'
    # Domain <-> DomainAdmin <-> Admin
    has_many :domain_admins, foreign_key: :domain, dependent: :delete_all

    has_many :admins, through: :domain_admins

    before_validation do |domain|
      domain.domain = domain.domain&.downcase
      domain.transport = "virtual"
    end

    scope :without_all, -> { where.not(domain: "ALL") }

    # aliases that don't belong to a mailbox
    def pure_aliases
      rel_aliases.pure
    end

    def mailbox_count
      rel_mailboxes.count
    end

    def pure_alias_count
      pure_aliases.count
    end

    def mailbox_usage_display_str
      "%4d / %4s" % [mailbox_count, mailboxes_str]
    end

    def alias_usage_display_str
      "%4d / %4s" % [pure_alias_count, aliases_str]
    end

    def aliases_str
      max_num_str(aliases)
    end

    def mailboxes_str
      max_num_str(mailboxes)
    end

    def maxquota_str
      max_num_str(maxquota)
    end

    def mailbox_unlimited?
      mailboxes == UNLIMITED
    end

    def maxquota_unlimited?
      maxquota.zero?
    end

    private

    def max_num_str(num)
      case num
      when DISABLED
        "Disabled"
      when UNLIMITED
        "Unlimited"
      else
        num.to_s
      end
    end
  end
end
