require 'mysql2'
require_relative '../config/settings'

client = Mysql2::Client.new(Settings.mysql.select {|key, _| not key == 'database' })

query =<<"EOF"
CREATE DATABASE IF NOT EXISTS
  #{Settings.mysql['database']}
DEFAULT CHARACTER SET
  utf8
EOF
client.query(query)
client.close

client = Mysql2::Client.new(Settings.mysql)
Dir[File.join(Settings.application_root, 'db/schema/*.sql')].each do |sql_file|
  client.query(File.read(sql_file))
end

indexes = client.query('SHOW INDEX FROM rates')
%w[ time pair ].each do |column|
  unless indexes.any? {|index| index['Key_name'] == "index_#{column}" }
    client.query("ALTER TABLE rates ADD INDEX index_#{column}(#{column})")
  end
end
client.close
