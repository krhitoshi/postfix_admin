module PostfixAdmin
  class DomainAdmin < ApplicationRecord
    # version: 1841
    # > describe domain_admins;
    # +----------+--------------+------+-----+---------------------+-------+
    # | Field    | Type         | Null | Key | Default             | Extra |
    # +----------+--------------+------+-----+---------------------+-------+
    # | username | varchar(255) | NO   | MUL | NULL                |       |
    # | domain   | varchar(255) | NO   |     | NULL                |       |
    # | created  | datetime     | NO   |     | 2000-01-01 00:00:00 |       |
    # | active   | tinyint(1)   | NO   |     | 1                   |       |
    # +----------+--------------+------+-----+---------------------+-------+

    self.table_name = :domain_admins

    belongs_to :admin, primary_key: :username, foreign_key: :username
    belongs_to :rel_domain, class_name: "Domain", foreign_key: :domain
  end
end
