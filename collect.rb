require 'csv'
require 'date'
require 'fileutils'
require_relative 'config/settings'
require_relative 'lib/logger'
require_relative 'lib/mysql_client'

TARGET_DATE = (Date.today - 2).strftime('%F')
RATE_FILES = Dir[File.join(Settings.csv_dir, "*_#{TARGET_DATE}.csv")]
BACKUP_DIR = File.join(Settings.application_root, Settings.backup_dir)

client = MysqlClient.new

RATE_FILES.each do |rate_file|
  Logger.write_with_runtime(:action => 'import', :file_name => rate_file) do
    rates = CSV.read(rate_file, :converters => :all)
    rates.map! {|rate| [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]] }

    FileUtils.mkdir_p(File.dirname(Settings.tmp_file))
    CSV.open(Settings.tmp_file, 'w') do |csv|
      rates.each {|rate| csv << rate }
    end

    client.load(Settings.tmp_file, 'rates', %w[time pair bid ask])

    FileUtils.rm(Settings.tmp_file)
  end
end

unless RATE_FILES.empty?
  FileUtils.mkdir_p(BACKUP_DIR)
  file_name = File.join(BACKUP_DIR, "#{TARGET_DATE}.csv")

  Logger.write_with_runtime(:action => 'export', :file_name => File.basename(file_name)) do
    CSV.open(file_name, 'w') do |csv|
      client.select(['*'], 'rates', "DATE(time) = '#{TARGET_DATE}'").each do |rate|
        csv << [rate['id'], rate['time'].strftime('%F %T'), rate['pair'], rate['bid'], rate['ask']]
      end
    end
  end
end
