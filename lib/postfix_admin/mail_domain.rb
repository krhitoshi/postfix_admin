module PostfixAdmin
  class MailDomain < ApplicationRecord
    self.table_name = :domain
    self.primary_key = :domain

    has_many :addresses, class_name: "Mailbox", foreign_key: :domain,
                         dependent: :destroy
  end
end
