require 'mysql2'
require_relative 'logger'
require_relative '../config/settings'

class MysqlClient
  def initialize
    @client = Mysql2::Client.new(Settings.mysql)
  end

  def load(file, table, columns = [])
    variables = columns.map.with_index do |_, i|
      "@#{i + 1}"
    end.join(',')

    values = columns.map.with_index do |column, i|
      "#{column}=@#{i + 1}"
    end.join(',')

    start_time = Time.now
    execute_query("LOAD DATA LOCAL INFILE '#{file}' INTO TABLE #{table} FIELDS TERMINATED BY ',' (#{variables}) SET #{values}")
    end_time = Time.now
    body = {
      :param => {:file => file, :table => table, :columns => columns},
      :stat => {:size => File.stat(file).size, :line => File.read(file).lines.size},
      :mysql_runtime => (end_time - start_time),
    }
    Logger.info(body)
  end

  def select(attributes, table, condition = 'TRUE')
    start_time = Time.now
    results = execute_query("SELECT #{attributes.join(',')} FROM #{table} WHERE #{condition}")
    end_time = Time.now
    client.close

    body = {
      :num_of_rates => results.size,
      :mysql_runtime => (end_time - start_time),
    }
    Logger.info(body)
    results
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
