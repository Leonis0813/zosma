require 'csv'
require 'fileutils'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../config/initialize'
require_relative '../db/connect'
require_relative '../lib/import_util'
require_relative '../lib/zosma_logger'
require_relative '../models/application_record'
require_relative '../models/moving_average'

BACKUP_DIR = File.join(APPLICATION_ROOT, Settings.import.file.moving_average.backup_dir)
logger = ZosmaLogger.new(Settings.logger.path.import)
ApplicationRecord.logger = logger

begin
  from = ARGV.find {|arg| arg.start_with?('--from=') }
  from = from ? Date.parse(from.match(/\A--from=(.*)\z/)[1]) : (Date.today - 2)
  to = ARGV.find {|arg| arg.start_with?('--to=') }
  to = to ? Date.parse(to.match(/\A--to=(.*)\z/)[1]) : Date.today
rescue ArgumentError => e
  logger.error(e.backtrace.join("\n"))
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
    logger.info(
      action: 'unpack',
      file: File.basename(tar_gz_file),
      size: File.stat(tar_gz_file).size,
    )
  else
    src_dir = Settings.import.file.moving_average.src_dir
    [
      Dir[File.join(BACKUP_DIR, "#{yearmonth}-*.csv")],
      Dir[File.join(src_dir, "*_#{yearmonth}-*.csv")],
    ].each do |csv_files|
      FileUtils.cp(csv_files, dir)
      logger.info(
        action: 'copy',
        files: csv_files.map {|file| File.basename(file) },
      )
    end
  end
end

tmp_file_name = File.join(dir, 'moving_averages.csv')

(from..to).each do |date|
  date_string = date.strftime('%F')

  ImportUtil.target_files(dir, date_string).each do |file|
    CSV.open(tmp_file_name, 'w') do |csv|
      moving_averages = CSV.read(file)
      logger.info(action: 'read', file: File.basename(file), size: File.stat(file).size)
      moving_averages.each {|moving_average| csv << moving_average }
    end

    MovingAverage.load_data(tmp_file_name)
  end
end

FileUtils.rm_r(dir)
