require 'csv'
require 'fileutils'
require 'logger'
require_relative 'config/initialize'
require_relative 'db/connect'
Dir['models/*'].each {|f| require_relative f }

TARGET_DATE = (Date.today - 2).strftime('%F')
TARGET_FILES = Dir[File.join(Settings.csv_dir, "*_#{TARGET_DATE}.csv")]
BACKUP_DIR = File.join(APPLICATION_ROOT, Settings.backup_dir)

TARGET_FILES.each do |rate_file|
  rates = CSV.read(rate_file, :converters => :all)
  rates.map! {|rate| [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]] }

  FileUtils.mkdir_p(File.dirname(Settings.tmp_file))
  CSV.open(Settings.tmp_file, 'w') do |csv|
    rates.each {|rate| csv << rate }
  end

  client.load(Settings.tmp_file, 'rates', %w[time pair bid ask])

  FileUtils.rm(Settings.tmp_file)
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
