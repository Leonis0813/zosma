class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  cattr_accessor :logger

  def self.load_data(file_name, ids, variables, table_name)
    sql = <<-"SQL"
  LOAD DATA LOCAL INFILE '#{file_name}'
  IGNORE INTO TABLE #{table_name}
  FIELDS TERMINATED BY ',' (#{ids.join(',')}) SET #{variables.join(',')}
SQL

    file_line_size = File.read(file_name).lines.size
    sql_start = Time.now
    ActiveRecord::Base.connection.execute(sql)
    logger.info(action: 'load', line: file_line_size, runtime: Time.now - sql_start)
  end
end
