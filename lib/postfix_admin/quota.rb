module PostfixAdmin
  class Quota < ApplicationRecord
    # version: 1841
    # > describe quota;
    # +----------+--------------+------+-----+---------+-------+
    # | Field    | Type         | Null | Key | Default | Extra |
    # +----------+--------------+------+-----+---------+-------+
    # | username | varchar(255) | NO   | PRI | NULL    |       |
    # | path     | varchar(100) | NO   | PRI | NULL    |       |
    # | current  | bigint(20)   | YES  |     | NULL    |       |
    # +----------+--------------+------+-----+---------+-------+

    self.table_name = :quota2
    self.primary_key = :username
  end
end
