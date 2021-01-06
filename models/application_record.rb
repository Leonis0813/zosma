class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  cattr_accessor :logger

  def self.load_data(file_name)
    headers = self.attribute_names - %w[id created_at updated_at]
    ids = headers.size.times.map {|i| "@#{i + 1}" }
    variables = headers.map.with_index(1) {|header, i| "`#{header}`=@#{i}" }
    variables += %w[created_at=now() updated_at=now()]

    sql = <<-"SQL"
  LOAD DATA LOCAL INFILE '#{file_name}'
  IGNORE INTO TABLE #{self.table_name}
  FIELDS TERMINATED BY ',' (#{ids.join(',')}) SET #{variables.join(',')}
SQL

    file_line_size = File.read(file_name).lines.size
    sql_start = Time.now
    connection.execute(sql)
    logger.info(action: 'load', line: file_line_size, runtime: Time.now - sql_start)

    connection.execute("ALTER TABLE #{self.table_name} AUTO_INCREMENT = #{last.id + 1}")
  end
end
