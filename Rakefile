require "bundler/gem_tasks"
require "rake/testtask"
require "rspec/core/rake_task"

require "bundler/setup"
Bundler.require(:default, :development)
require "postfix_admin"
require "postfix_admin/cli"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

RSpec::Core::RakeTask.new(:spec)

task default: :test

desc "Set up test database"
task :setup_test_db do
  create_db_cmd = "mysql -e 'CREATE DATABASE `postfix_test`;'"
  puts create_db_cmd
  puts `#{create_db_cmd}`

  import_db_cmd = "mysql postfix_test < docker-db/postfix.v1841.sql"
  puts import_db_cmd
  puts `#{import_db_cmd}`
end

namespace :db do
  desc "Loads the seed data from db/seeds.rb"
  task :seed do
    establish_db_connection
    require_relative "db/seeds"
  end

  namespace :seed do
    desc "Truncates tables of each database for current environment and loads the seeds"
    task :replant do
      establish_db_connection

      DomainAdmin.delete_all
      Mailbox.delete_all
      Alias.delete_all
      Domain.without_all.delete_all
      Admin.delete_all
      Quota2.delete_all
      Log.delete_all

      require_relative "db/seeds"
    end
  end

  def establish_db_connection
    include FactoryBot::Syntax::Methods
    FactoryBot.find_definitions

    PostfixAdmin::CLI.new.db_setup
  end
end
