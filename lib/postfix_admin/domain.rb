module PostfixAdmin
  class Domain < ApplicationRecord
    self.table_name = :domain
    self.primary_key = :domain

    validates :domain, presence: true, uniqueness: { case_sensitive: false },
                       format: { with: RE_DOMAIN_NAME_LIKE_WITH_ANCHORS,
                                 message: "must be a valid domain name" }
    validates :transport, presence: true

    validates :aliases, presence: true,
                        numericality: { only_integer: true,
                                        greater_than_or_equal_to: 0 }
    validates :mailboxes, presence: true,
                          numericality: { only_integer: true,
                                          greater_than_or_equal_to: 0 }

    # max quota (MB) for each mailbox
    validates :maxquota, presence: true,
                         numericality: { only_integer: true,
                                         greater_than_or_equal_to: 0 }

    has_many :rel_mailboxes, class_name: "Mailbox", foreign_key: :domain,
                             dependent: :destroy
    has_many :rel_aliases, class_name: "Alias", foreign_key: :domain,
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
    has_many :domain_admins, foreign_key: :domain, dependent: :delete_all

    has_many :admins, through: :domain_admins

    before_validation do |domain|
      domain.domain = domain.domain.downcase unless domain.domain.empty?
      domain.transport = "virtual"
    end

    scope :without_all, -> { where.not(domain: "ALL") }

    def pure_aliases
      rel_aliases.pure
    end

    def aliases_unlimited?
      aliases.zero?
    end

    def mailboxes_unlimited?
      mailboxes.zero?
    end

    def aliases_str
      num_str(aliases)
    end

    def mailboxes_str
      num_str(mailboxes)
    end

    def aliases_short_str
      num_short_str(aliases)
    end

    def mailboxes_short_str
      num_short_str(mailboxes)
    end

    def maxquota_str
      case maxquota
      when -1
        # It's not sure what 'disabled' means for max quota.
        "Disabled"
      when 0
        "Unlimited"
      else
        maxquota.to_s
      end
    end

    private

    def num_str(num)
      if num.zero?
        "Unlimited"
      else
        num.to_s
      end
    end

    def num_short_str(num)
      if num.zero?
        "--"
      else
        num.to_s
      end
    end
  end
end
