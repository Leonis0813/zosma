require 'active_record'
require 'mysql2'
require_relative '../config/initialize'

ActiveRecord::Base.establish_connection(Settings.mysql.to_h)
