require_relative '../config/initialize'
require_relative '../db/connect'
Dir[File.join(APPLICATION_ROOT, 'models/*')].each {|f| require_relative f }

logger = ZosmaLogger.new(Settings.logger.path.restore)
ApplicationRecord.logger = logger
ZipUtil.logger = logger

begin
  from = ARGV.find {|arg| arg.start_with?('--from=') }
  from = from ? Date.parse(from.match(/\A--from=(.*)\z/)[1]) : (Date.today - 2)
  to = ARGV.find {|arg| arg.start_with?('--to=') }
  to = to ? Date.parse(to.match(/\A--to=(.*)\z/)[1]) : Date.today
rescue ArgumentError => e
  logger.error(e.backtrace.join("\n"))
  raise e
end

logger.info("==== Start restore ====")
logger.info("FROM: #{from.strftime('%F')}")
logger.info("TO: #{to.strftime('%F')}")
start_time = Time.now

(from..to).each do |date|
  [
    ['rate', Rate],
    ['candle_stick', CandleStick],
    ['moving_average', MovingAverage],
  ].each do |type, klass|
    backup_dir = File.join(APPLICATION_ROOT, Settings.import.file[type].backup_dir)
    klass.load_data(File.join(backup_dir, "#{date.strftime('%F')}.csv"))
  end
end

logger.info("==== Finish restore (run_time: #{Time.now - start_time}) ====")
