require_relative '../config/initialize'
require_relative '../db/connect'
Dir[File.join(APPLICATION_ROOT, 'models/*')].each {|f| require_relative f }

logger = ZosmaLogger.new(Settings.logger.path.restore)

logger.info('============ Start Restore ============')

begin
  from = ARGV.find {|arg| arg.start_with?('--from=') }
  from = from ? Date.parse(from.match(/\A--from=(.*)\z/)[1]) : (Date.today - 2)
  to = ARGV.find {|arg| arg.start_with?('--to=') }
  to = to ? Date.parse(to.match(/\A--to=(.*)\z/)[1]) : Date.today
rescue ArgumentError => e
  logger.error(e.backtrace.join("\n"))
  raise e
end

logger.info('Parameter')
logger.info("  from: #{from}")
logger.info("  to: #{to}")

(from..to).each do |date|
  logger.info("======== Restore data on #{date}")

  [
    ['rate', Rate],
    ['candle_stick', CandleStick],
    ['moving_average', MovingAverage],
  ].each do |type, klass|
    logger.info("==== Restore #{type}")

    backup_dir = File.join(APPLICATION_ROOT, Settings.import.file[type].backup_dir)
    file_name = File.join(backup_dir, "#{date.strftime('%F')}.csv")

    unless File.exist?(file_name)
      logger.warn("#{file_name} is not exist")
      next
    end

    last_id_before = klass.select(:id).order(desc: :id).limit(1).first.id
    klass.load_data(file_name)
    last_id_after = klass.select(:id).order(desc: :id).limit(1).first.id
    logger.info("Load #{last_id_after - last_id_before} records")
  end

  logger.info('====')
end

logger.info('========')
logger.info('============ Finish Restore ============')
