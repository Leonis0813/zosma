require_relative '../config/initialize'
require_relative '../db/connect'
require_relative '../models/candle_stick'

logger = ZosmaLogger.new(Settings.logger.path.import)

logger.info('============ Start Import ============')

begin
  from = ARGV.find {|arg| arg.start_with?('--from=') }
  from = from ? Date.parse(from.match(/\A--from=(.*)\z/)[1]) : (Date.today - 7)
  to = ARGV.find {|arg| arg.start_with?('--to=') }
  to = to ? Date.parse(to.match(/\A--to=(.*)\z/)[1]) : Date.today
rescue ArgumentError => e
  logger.error(e.backtrace.join("\n"))
  raise e
end

logger.info('Parameter:')
logger.info("  from: #{from}")
logger.info("  to: #{to}")

(from..to).each do |date|
  Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |tmp_dir|
    tmp_file_name = File.join(tmp_dir, 'candle_sticks.csv')

    file_pattern = "*_#{date.strftime('%F')}.csv"
    logger.info("======== Import #{file_pattern}")

    target_files =
      Dir[File.join(Settings.import.file.candle_stick.src_dir, file_pattern)]
    logger.info("Target Files: #{target_files}")

    FileUtils.cp(target_files, tmp_dir)

    Dir[File.join(tmp_dir, file_pattern)].each do |file|
      logger.info("==== Import #{file}")

      FileUtils.cp(file, tmp_file_name)
      logger.info("Copy #{file} to #{tmp_file_name} (#{File.stat(file).size} bytes)")

      last_id_before = CandleStick.select(:id).order(id: :desc).limit(1).first.id
      CandleStick.load_data(tmp_file_name)
      last_id_after = CandleStick.select(:id).order(id: :desc).limit(1).first.id
      logger.info("Load #{last_id_after - last_id_before} candle sticks to table")
    end

    logger.info('====')
  end
end

logger.info('========')
logger.info('============ Finish Import ============')
