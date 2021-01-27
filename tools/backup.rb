require 'csv'
require 'fileutils'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../config/initialize'
require_relative '../db/connect'
require_relative '../lib/zip_util'
require_relative '../lib/zosma_logger'
Dir[File.join(APPLICATION_ROOT, 'models/*')].each {|f| require_relative f }

logger = ZosmaLogger.new(Settings.logger.path.backup)
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

logger.info("==== Start backup (from: #{from.strftime('%F')}, to: #{to.strftime('%F')})")
start_time = Time.now

periods = []
(from..to).each do |date|
  froms = periods.map {|period| period[:from].strftime('%Y-%m') }
  unless froms.include?(date.strftime('%Y-%m'))
    periods << {from: date, to: Date.new(date.year, date.month, -1)}
  end
end
periods.last[:to] = to

periods.each do |period|
  yearmonth = period[:from].strftime('%Y-%m')

  [
    ['rate', Rate],
    ['candle_stick', CandleStick],
    ['moving_average', MovingAverage],
  ].each do |type, klass|
    backup_dir = File.join(APPLICATION_ROOT, Settings.import.file[type].backup_dir)
    old_tar_gz_file = File.join(backup_dir, "#{yearmonth}.tar.gz")

    if File.exist?(old_tar_gz_file)
      dir = Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir))

      ZipUtil.read(old_tar_gz_file, dir) do
        FileUtils.mv(Dir[File.join(dir, yearmonth, '*')], dir)
        FileUtils.rm_rf(File.join(dir, yearmonth))
        FileUtils.mkdir_p(File.join(dir, yearmonth))
      end

      (period[:from]..period[:to]).each do |date|
        klass.dump(File.join(dir, yearmonth, "#{date.strftime('%F')}.csv"), date)
      end

      new_tar_gz_file = File.join(dir, "#{yearmonth}.tar.gz")
      ZipUtil.write(new_tar_gz_file, dir, File.join(yearmonth, '*.csv'))
      FileUtils.mv(new_tar_gz_file, old_tar_gz_file)
      FileUtils.mv(Dir[File.join(dir, '*.csv')], backup_dir)
      FileUtils.mv(Dir[File.join(dir, yearmonth, '*.csv')], backup_dir)
      FileUtils.rm_r(dir)
    else
      (period[:from]..period[:to]).each do |date|
        klass.dump(File.join(backup_dir, "#{date.strftime('%F')}.csv"), date)
      end
    end
  end
end

logger.info("==== Finish backup (run_time: #{Time.now - start_time})")
