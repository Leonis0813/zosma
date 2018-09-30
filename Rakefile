require 'active_record'
require 'logger'
require 'mysql2'
require_relative 'config/initialize'

task :default => :migrate

namespace :db do
  desc 'Drop and create database'
  task :reset => :environment do
    ActiveRecord::Tasks::DatabaseTasks.drop_current(ENV['RAILS_ENV'])
    ActiveRecord::Tasks::DatabaseTasks.create_current(ENV['RAILS_ENV'])
  end

  desc 'Migrate database'
  task :migrate => :environment do
    ActiveRecord::Base.establish_connection(ENV['RAILS_ENV'].to_sym)
    ActiveRecord::Migrator.migrate('db/migrate', ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
  end

  task :environment do
    ENV['RAILS_ENV'] ||= 'development'
    settings = Settings.mysql.map {|key, value| [key.to_s, value] }.to_h
    ActiveRecord::Tasks::DatabaseTasks.database_configuration = settings
    ActiveRecord::Base.configurations = {ENV['RAILS_ENV'] => settings}
    ActiveRecord::Base.logger = Logger.new('log/database.log')
  end
end
