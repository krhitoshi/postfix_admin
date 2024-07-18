require "postfix_admin/models/application_record"

module PostfixAdmin
  class Log < ApplicationRecord
    # version: 1841
    # > describe log;
    # +-----------+--------------+------+-----+---------------------+----------------+
    # | Field     | Type         | Null | Key | Default             | Extra          |
    # +-----------+--------------+------+-----+---------------------+----------------+
    # | timestamp | datetime     | NO   | MUL | 2000-01-01 00:00:00 |                |
    # | username  | varchar(255) | NO   |     | NULL                |                |
    # | domain    | varchar(255) | NO   | MUL | NULL                |                |
    # | action    | varchar(255) | NO   |     | NULL                |                |
    # | data      | text         | NO   |     | NULL                |                |
    # | id        | int(11)      | NO   | PRI | NULL                | auto_increment |
    # +-----------+--------------+------+-----+---------------------+----------------+

    self.table_name = :log

    belongs_to :rel_domain, class_name: "Domain", foreign_key: :domain
  end
end
