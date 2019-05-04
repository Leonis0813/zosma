def target_files(csv_dir, date_string)
  csv_file = File.join(csv_dir, "#{date_string}.csv")
  if File.exist?(csv_file)
    [csv_file]
  else
    Dir[File.join(csv_dir, "*_#{date_string}.csv")]
  end
end

def load_data(file_name, ids, variables, table_name)
  sql = <<-"SQL"
    LOAD DATA LOCAL INFILE '#{file_name}'
    INTO TABLE #{table_name}
    FIELDS TERMINATED BY ',' (#{ids.join(',')}) SET #{variables.join(',')}
  SQL

  file_line_size = File.read(file_name).lines.size
  sql_start = Time.now
  ActiveRecord::Base.connection.execute(sql)
  LOGGER.info(action: 'load', line: file_line_size, runtime: Time.now - sql_start)

  sql = "ALTER TABLE #{table_name} AUTO_INCREMENT = #{file_line_size + 1}"
  ActiveRecord::Base.connection.execute(sql)
end
