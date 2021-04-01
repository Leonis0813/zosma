require_relative '../config/initialize'
require_relative '../db/connect'
require_relative '../lib/zip_util'
Dir[File.join(APPLICATION_ROOT, 'models/*')].each {|f| require_relative f }

logger = ZosmaLogger.new(Settings.logger.path.backup)

logger.info('================ Start Backup ================')

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

logger.info('============ Calculate Target Period')

periods = []
(from..to).each do |date|
  froms = periods.map {|period| period[:from].strftime('%Y-%m') }
  unless froms.include?(date.strftime('%Y-%m'))
    periods << {from: date, to: Date.new(date.year, date.month, -1)}
  end
end
periods.last[:to] = to

periods.each.with_index(1) do |period, i|
  logger.info("#{i}. #{period[:from]} - #{period[:to]}")
end

periods.each do |period|
  logger.info("============ Backup #{period[:from]} - #{period[:to]}")

  yearmonth = period[:from].strftime('%Y-%m')

  [
    ['rate', Rate],
    ['candle_stick', CandleStick],
    ['moving_average', MovingAverage],
  ].each do |type, klass|
    logger.info("======== Backup #{klass.table_name} table")

    backup_dir = File.join(APPLICATION_ROOT, Settings.import.file[type].backup_dir)
    old_tar_gz_file = File.join(backup_dir, "#{yearmonth}.tar.gz")

    if File.exist?(old_tar_gz_file)
      dir = Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir))

      ZipUtil.read(old_tar_gz_file, dir) do
        FileUtils.mv(Dir[File.join(dir, yearmonth, '*')], dir)
        FileUtils.rm_rf(File.join(dir, yearmonth))
        FileUtils.mkdir_p(File.join(dir, yearmonth))
      end
      logger.info("Unzip #{old_tar_gz_file} to #{dir}")

      (period[:from]..period[:to]).each do |date|
        logger.info("==== Backup Data on #{date}")

        file_path = File.join(dir, yearmonth, "#{date.strftime('%F')}.csv")
        klass.dump(file_path, date)

        lines = File.read(file_path).lines.size
        bytes = File.stat(file_path).size
        logger.info("Dump to #{file_path} (#{lines} lines, #{bytes} bytes)")
      end

      logger.info('====')

      new_tar_gz_file = File.join(dir, "#{yearmonth}.tar.gz")
      ZipUtil.write(new_tar_gz_file, dir, File.join(yearmonth, '*.csv'))
      logger.info("Zip #{File.join(dir, yearmonth, '*.csv')}")

      FileUtils.mv(new_tar_gz_file, old_tar_gz_file)
      FileUtils.mv(Dir[File.join(dir, '*.csv')], backup_dir)
      FileUtils.mv(Dir[File.join(dir, yearmonth, '*.csv')], backup_dir)
      FileUtils.rm_r(dir)
    else
      (period[:from]..period[:to]).each do |date|
        logger.info("==== Backup Data on #{date}")

        file_path = File.join(backup_dir, "#{date.strftime('%F')}.csv")
        klass.dump(file_path, date)
        next unless File.exist?(file_path)

        lines = File.read(file_path).lines.size
        bytes = File.stat(file_path).size
        logger.info("Dump to #{file_path} (#{lines} lines, #{bytes} bytes)")
      end

      logger.info('====')
    end
  end

  logger.info('========')
end

logger.info('============')
logger.info('================ Finish Backup ================')
