module PostfixAdmin
  class Quota < ApplicationRecord
    # version: 1841
    # > describe quota2;
    # +----------+--------------+------+-----+---------+-------+
    # | Field    | Type         | Null | Key | Default | Extra |
    # +----------+--------------+------+-----+---------+-------+
    # | username | varchar(100) | NO   | PRI | NULL    |       |
    # | bytes    | bigint(20)   | NO   |     | 0       |       |
    # | messages | int(11)      | NO   |     | 0       |       |
    # +----------+--------------+------+-----+---------+-------+

    self.table_name = :quota2
    self.primary_key = :username
  end
end
