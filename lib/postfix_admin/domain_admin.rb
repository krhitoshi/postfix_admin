module PostfixAdmin
  class DomainAdmin < ApplicationRecord
    self.table_name = :domain_admins

    belongs_to :admin, primary_key: :username, foreign_key: :username
    belongs_to :rel_domain, class_name: "Domain", foreign_key: :domain
  end
end
