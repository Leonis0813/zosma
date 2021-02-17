class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  cattr_accessor :zosma_logger

  def self.load_data(file_name)
    headers = attribute_names - %w[id created_at updated_at]
    ids = Array.new(headers.size) {|i| "@#{i + 1}" }
    variables = headers.map.with_index(1) {|header, i| "`#{header}`=@#{i}" }
    variables += %w[created_at=now() updated_at=now()]

    sql = <<-"SQL"
      LOAD DATA LOCAL INFILE '#{file_name}'
      IGNORE INTO TABLE #{table_name}
      FIELDS TERMINATED BY ',' (#{ids.join(',')}) SET #{variables.join(',')}
    SQL

    file_line_size = File.read(file_name).lines.size
    sql_start = Time.now
    connection.execute(sql)
    runtime = Time.now - sql_start
    zosma_logger.info(action: 'load', line: file_line_size, runtime: runtime)

    connection.execute("ALTER TABLE #{table_name} AUTO_INCREMENT = #{last.id + 1}")
  end

  def self.dump(file_name, date)
    records = on(date)
    return unless records.exists?

    CSV.open(file_name, 'w') do |csv|
      records.each {|record| csv << record.to_csv }

      zosma_logger.info(
        action: 'dump',
        file: File.basename(file_name),
        lines: records.size,
        size: File.stat(file_name).size,
      )
    end
  end
end
