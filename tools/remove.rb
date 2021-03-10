require_relative '../config/initialize'
require_relative '../db/connect'
Dir[File.join(APPLICATION_ROOT, 'models/*')].each {|f| require_relative f }

TARGET_DATE = (Date.today - 2).strftime('%F')
logger = ZosmaLogger.new(Settings.logger.path.remove)

logger.info('======== Start Remove ========')
logger.info("Date: #{TARGET_DATE}")

[
  ['rate', Rate, 'time'],
  ['candle_stick', CandleStick, 'to'],
  ['moving_average', MovingAverage, 'time'],
].each do |directory, target_class, index_key|
  logger.info("==== Remove #{directory}")

  target_dir = Settings.import.file[directory]

  backup_file = File.join(target_dir.backup_dir, "#{TARGET_DATE}.csv")
  next unless File.exist?(backup_file)

  lines = CSV.read(backup_file).size
  bytes = File.stat(backup_file).size
  logger.info("Read #{backup_file} (#{lines} lines, #{bytes} bytes)")

  record_size = target_class.where("DATE(`#{index_key}`) = ?", TARGET_DATE).size
  logger.info("Read #{target_class.table_name} table (#{record_size} records)")

  next unless line_size == db_size

  src_files = Dir[File.join(target_dir.src_dir, "*_#{TARGET_DATE}.csv")]
  FileUtils.rm(src_files)
  logger.info("Remove files: #{src_files}")
end

logger.info('====')
logger.info('======== Finish Remove ========')
