require "csv"
require 'fileutils'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../config/initialize'
require_relative '../db/connect'
require_relative '../lib/import_util'
require_relative '../lib/zosma_logger'
require_relative '../models/candle_stick'

BACKUP_DIR = File.join(APPLICATION_ROOT, Settings.import.file.candle_stick.backup_dir)
LOGGER = ZosmaLogger.new(Settings.logger.path.import)

begin
  from = ARGV.find {|arg| arg.start_with?('--from=') }
  from = from ? Date.parse(from.match(/\A--from=(.*)\z/)[1]) : (Date.today - 2)
  to = ARGV.find {|arg| arg.start_with?('--to=') }
  to = to ? Date.parse(to.match(/\A--to=(.*)\z/)[1]) : (Date.today - 2)
rescue ArgumentError => e
  LOGGER.error(e.backtrace.join("\n"))
  raise e
end

dir = Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir))

(from.strftime('%Y-%m')..to.strftime('%Y-%m')).each do |yearmonth|
  tar_gz_file = File.join(BACKUP_DIR, "#{yearmonth}.tar.gz")

  if File.exist?(tar_gz_file)
    Zlib::GzipReader.open(tar_gz_file) do |file|
      Archive::Tar::Minitar.unpack(file, dir)
    end
    FileUtils.mv(Dir[File.join(dir, yearmonth, '*')], dir)
    LOGGER.info(
      action: 'unpack',
      file: File.basename(tar_gz_file),
      size: File.stat(tar_gz_file).size,
    )
  else
    [
      Dir[File.join(BACKUP_DIR, "#{yearmonth}-*.csv")],
      Dir[File.join(Settings.import.file.candle_stick.src_dir, "*_#{yearmonth}-*.csv")],
    ].each do |csv_files|
      FileUtils.cp(csv_files, dir)
      LOGGER.info(
        action: 'copy',
        files: csv_files.map {|file| File.basename(file) },
      )
    end
  end
end

tmp_file_name = File.join(dir, 'candle_sticks.csv')

(from..to).each do |date|
  date_string = date.strftime('%F')

  target_files(dir, date_string).each do |file|
    CSV.open(tmp_file_name, 'w') do |csv|
      candle_sticks = CSV.read(file)
      LOGGER.info(action: 'read', file: File.basename(file), size: File.stat(file).size)
      candle_sticks.each {|candle_stick| csv << candle_stick }
    end

    headers = CandleStick.attribute_names - %w[id created_at updated_at]
    ids = headers.size.times.map {|i| "@#{i + 1}" }
    variables = headers.map.with_index(1) {|header, i| "`#{header}`=@#{i}" }
    variables += %w[created_at=now() updated_at=now()]
    load_data(tmp_file_name, ids, variables, CandleStick.table_name)
  end

  backup_file = File.join(BACKUP_DIR, "#{date_string}.csv")
  next if File.exist?(backup_file) or
          File.exist?(File.join(BACKUP_DIR, "#{date.strftime('%Y-%m')}.tar.gz"))

  candle_sticks = CandleStick.where('DATE(`to`) = ?', date_string)
  next if candle_sticks.empty?

  FileUtils.mkdir_p(BACKUP_DIR)

  CSV.open(backup_file, 'w') do |csv|
    candle_sticks.each do |candle_stick|
      csv << [
        candle_stick.from.strftime('%F %T'),
        candle_stick.to.strftime('%F %T'),
        candle_stick.pair,
        candle_stick.time_frame,
        candle_stick.open,
        candle_stick.close,
        candle_stick.high,
        candle_stick.low,
      ]
    end

    LOGGER.info(
      action: 'backup',
      file: File.basename(backup_file),
      lines: candle_sticks.size,
      size: File.stat(backup_file).size,
    )
  end
end

FileUtils.rm_r(dir)
