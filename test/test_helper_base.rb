# common methods for tests and specs

def setup_db_connection
  database = if ENV["CI"]
               "mysql2://root:ScRgkaMz4YwHN5dyxfQj@127.0.0.1:13306/postfix_test"
             else
               "mysql2://root:ScRgkaMz4YwHN5dyxfQj@db:3306/postfix_test"
             end
  ENV["DATABASE_URL"] = database
  ActiveRecord::Base.establish_connection(database)
end

def db_reset
  DomainAdmin.delete_all
  Mailbox.delete_all
  Alias.delete_all
  Domain.without_all.delete_all
  Admin.delete_all
end
