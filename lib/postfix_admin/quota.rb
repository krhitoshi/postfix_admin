module PostfixAdmin
  class Quota < ApplicationRecord
    self.table_name = :quota2
    self.primary_key = :username
  end
end
