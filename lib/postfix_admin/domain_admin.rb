module PostfixAdmin
  class DomainAdmin < ApplicationRecord
    self.table_name = :domain_admins

    belongs_to :admin, primary_key: :username, foreign_key: :username
    belongs_to :rel_domain, class_name: "Domain", foreign_key: :domain

    # domain_admins table does not have timestamp columns
    def set_current_time_to_timestamp_columns
    end
  end
end
