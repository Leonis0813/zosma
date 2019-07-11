require 'active_record'
require 'mysql2'
require_relative '../config/initialize'
require_relative '../lib/zosma_logger'

ActiveRecord::Base.logger = ZosmaLogger.new(Settings.logger.path.database)
ActiveRecord::Base.logger.level = Settings.logger.level.to_sym
settings = Settings.mysql.map {|key, value| [key.to_s, value] }.to_h
ActiveRecord::Base.establish_connection(settings)
