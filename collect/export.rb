require 'csv'
require_relative '../config/settings'
require_relative '../lib/logger'
require_relative '../lib/mysql_client'

def export(date)
  file_name = File.join(Settings.application_root, Settings.backup_dir, "#{date.strftime('%F')}.csv")

  Logger.write_with_runtime(:action => 'export', :file_name => File.basename(file_name)) do
    CSV.open(file_name, 'w') do |csv|
      MySQLClient.new.select('*', 'rates', "DATE(time) = #{date.strftime('%F')}").each do |rate|
        csv << [rate['id'], rate['time'].strftime('%F %T'), rate['pair'], rate['bid'], rate['ask']]
      end
    end
  end
end
