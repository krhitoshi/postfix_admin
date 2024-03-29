module PostfixAdmin
  class Alias < ApplicationRecord
    self.table_name = :alias
    self.primary_key = :address

    validate on: :create do |a|
      domain = a.rel_domain
      if domain.aliases.zero? || a.mailbox
      elsif domain.rel_aliases.pure.count >= domain.aliases
        message = "already has the maximum number of aliases " \
                  "(maximum is #{domain.aliases} aliases)"
        a.errors.add(:domain, message)
      end
    end

    validates :address, presence: true, uniqueness: { case_sensitive: false },
                        format: { with: RE_EMAIL_LIKE_WITH_ANCHORS,
                                  message: "must be a valid email address" }
    validates :goto, presence: true

    belongs_to :rel_domain, class_name: "Domain", foreign_key: :domain
    belongs_to :mailbox, foreign_key: :address, optional: true

    scope :pure, -> { joins("LEFT OUTER JOIN mailbox ON alias.address = mailbox.username").where("mailbox.username" => nil) }

    attribute :local_part, :string

    before_validation do |a|
      unless a.address
        a.address = "#{a.local_part}@#{a.domain}" unless a.local_part.empty?
      end
    end

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