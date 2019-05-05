require 'active_record'
require 'mysql2'
require_relative 'config/initialize'
require_relative 'lib/zosma_logger'

task default: :migrate

namespace :db do
  desc 'Create the database'
  task create: :environment do
    ActiveRecord::Tasks::DatabaseTasks.create_current(ENV['RAILS_ENV'])
  end

  desc 'Migrate database'
  task migrate: :environment do
    ActiveRecord::Base.establish_connection(ENV['RAILS_ENV'].to_sym)
    ActiveRecord::MigrationContext.new('db/migrate')
                                  .migrate(ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
  end

  desc 'Drop and create database'
  task reset: :environment do
    ActiveRecord::Tasks::DatabaseTasks.drop_current(ENV['RAILS_ENV'])
    ActiveRecord::Tasks::DatabaseTasks.create_current(ENV['RAILS_ENV'])
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n)'
  task rollback: :environment do
    ActiveRecord::Base.establish_connection(ENV['RAILS_ENV'].to_sym)
    ActiveRecord::MigrationContext.new('db/migrate')
                                  .rollback(ENV['STEP'] ? ENV['STEP'].to_i : 1)
  end

  task :environment do
    ENV['RAILS_ENV'] ||= 'development'
    settings = Settings.mysql.map {|key, value| [key.to_s, value] }.to_h
    ActiveRecord::Tasks::DatabaseTasks.database_configuration = settings
    ActiveRecord::Base.configurations = {ENV['RAILS_ENV'] => settings}
    ActiveRecord::Base.logger = ZosmaLogger.new('log/database.log')
  end
end
