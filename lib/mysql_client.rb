require 'mysql2'
require_relative 'logger'
require_relative '../config/settings'

class MySQLClient
  SQL_PATH = File.join(Settings.application_root, 'aggregate')

  def initialize
    @client = Mysql2::Client.new(Settings.mysql)
  end

  def import_rates(rate_file)
    query = File.read(File.join(SQL_PATH, 'import.sql'))

    start_time = Time.now
    execute_query(query.gsub('$FILE', rate_file))
    end_time = Time.now
    body = {
      :sql => 'import.sql',
      :param => {:file => rate_file},
      :stat => {:size => File.stat(rate_file).size, :line => File.read(rate_file).lines.size},
      :mysql_runtime => (end_time - start_time),
    }
    Logger.info(body)
  end

  def get_rates(date)
    query = File.read(File.join(SQL_PATH, 'export.sql'))
    day = date.strftime('%F')

    start_time = Time.now
    rates = execute_query(query.gsub('$DAY', day))
    end_time = Time.now
    body = {
      :sql => 'export.sql',
      :param => {:day => day},
      :num_of_rates => rates.size,
      :mysql_runtime => (end_time - start_time),
    }
    Logger.info(body)
    rates
  end

  def create_candle_sticks(param)
    query = File.read(File.join(Settings.application_root, 'aggregate.sql'))
    param.each {|key, value| query.gsub!("$#{key.upcase}", value) }

    start_time = Time.now
    execute_query(query)
    end_time = Time.now
    body = {
      :sql => 'aggregate.sql',
      :param => param,
      :mysql_runtime => (end_time - start_time),
    }
    Logger.info(body)
  end

  private

  def execute_query(query)
    begin
      @client.query(query)
    rescue
    end
  end
end
