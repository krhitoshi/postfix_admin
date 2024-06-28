module PostfixAdmin
  class Log < ApplicationRecord
    self.table_name = :log

    belongs_to :rel_domain, class_name: "Domain", foreign_key: :domain
  end
end
