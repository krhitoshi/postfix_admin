require "bundler/gem_tasks"
require "rake/testtask"
require "rspec/core/rake_task"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

RSpec::Core::RakeTask.new(:spec)

task default: :test

task :setup_test_db do
  create_db_cmd = "mysql -e 'CREATE DATABASE `postfix_test`;'"
  puts create_db_cmd
  puts `#{create_db_cmd}`

  import_db_cmd = "mysql postfix_test < docker-db/postfix.v1841.sql"
  puts import_db_cmd
  puts `#{import_db_cmd}`
end
