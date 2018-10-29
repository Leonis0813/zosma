require 'csv'
require 'fileutils'
require 'logger'
require_relative '../config/initialize'
require_relative '../db/connect'
Dir[File.join(APPLICATION_ROOT, 'models/*')].each {|f| require_relative f }

TARGET_DATE = (Date.today - 2).strftime('%F')

logger = Logger.new(Settings.logger.path.remove)
logger.formatter = proc do |severity, datetime, progname, message|
  time = datetime.utc.strftime(Settings.logger.time_format)
  log = "[#{severity}] [#{time}]: #{message}"
  puts log if ENV['STDOUT'] == 'on'
  "#{log}\n"
end

logger.info("==== Start removing (date: #{TARGET_DATE})")
start_time = Time.now

[
  ['rate', Rate, 'time'],
  ['candle_stick', CandleStick, 'to'],
].each do |directory, target_class, index_key|
  target_dir = Settings.import.file[directory]

  backup_file = File.join(target_dir.backup_dir, "#{TARGET_DATE}.csv")
  line_size = CSV.read(backup_file).size
  logger.info(
    :action => 'read',
    :file => File.basename(backup_file),
    :lines => line_size,
    :size => File.stat(backup_file).size
  )

  db_size = target_class.where("DATE(`#{index_key}`) = ?", TARGET_DATE).size
  logger.info(:action => 'compare', :backup_file_size => line_size, :db_size => db_size)

  if line_size == db_size
    src_files = Dir[File.join(target_dir.src_dir, "*_#{TARGET_DATE}.csv")]
    FileUtils.rm(src_files)
    logger.info(:action => 'remove', :removed_files => src_files)
  end
end

logger.info("==== Finish removing (run_time: #{Time.now - start_time})")
