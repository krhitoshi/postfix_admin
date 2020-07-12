module PostfixAdmin
  class Domain < ApplicationRecord
    self.table_name = :domain
    self.primary_key = :domain

    validates :domain, presence: true, uniqueness: true,
                       format: { with: RE_DOMAIN_NAME_LIKE_WITH_ANCHORS,
                                 message: "must be a valid domain name" }
    validates :transport, presence: true

    validates :aliases, presence: true,
                        numericality: { only_integer: true,
                                        greater_than_or_equal_to: 0 }
    validates :mailboxes, presence: true,
                          numericality: { only_integer: true,
                                          greater_than_or_equal_to: 0 }
    validates :maxquota, presence: true,
                         numericality: { only_integer: true,
                                         greater_than_or_equal_to: 0 }

    has_many :rel_mailboxes, class_name: "Mailbox", foreign_key: :domain,
                             dependent: :destroy
    has_many :rel_aliases, class_name: "Alias", foreign_key: :domain,
                           dependent: :destroy

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
      if maxquota.zero?
        "Unlimited"
      else
        "#{maxquota} MB"
      end
    end

    def maxquota_short_str
      if maxquota.zero?
        "--"
      else
        "#{maxquota} MB"
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
