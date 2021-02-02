require 'csv'
require 'fileutils'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../config/initialize'
require_relative '../db/connect'
require_relative '../lib/import_util'
require_relative '../lib/zip_util'
require_relative '../lib/zosma_logger'
require_relative '../models/rate'

BACKUP_DIR = File.join(APPLICATION_ROOT, Settings.import.file.rate.backup_dir)
logger = ZosmaLogger.new(Settings.logger.path.import)
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

dir = Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir))

(from.strftime('%Y-%m')..to.strftime('%Y-%m')).each do |yearmonth|
  tar_gz_file = File.join(BACKUP_DIR, "#{yearmonth}.tar.gz")

  if File.exist?(tar_gz_file)
    ZipUtil.read(tar_gz_file, dir) do
      FileUtils.mv(Dir[File.join(dir, yearmonth, '*')], dir)
    end
  else
    [
      Dir[File.join(BACKUP_DIR, "#{yearmonth}-*.csv")],
      Dir[File.join(Settings.import.file.rate.src_dir, "*_#{yearmonth}-*.csv")],
    ].each do |csv_files|
      FileUtils.cp(csv_files, dir)
      logger.info(
        action: 'copy',
        files: csv_files.map {|file| File.basename(file) },
      )
    end
  end
end

tmp_file_name = File.join(dir, 'rates.csv')

(from..to).each do |date|
  date_string = date.strftime('%F')

  ImportUtil.target_files(dir, date_string).each do |file|
    CSV.open(tmp_file_name, 'w') do |csv|
      rates = CSV.read(file, converters: :all).map do |rate|
        [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]]
      end
      logger.info(action: 'read', file: File.basename(file), size: File.stat(file).size)

      before_size = rates.size
      rates.uniq! {|rate| [rate[0], rate[1]] }
      logger.info(action: 'unique', before_size: before_size, after_size: rates.size)

      rates.each {|rate| csv << rate }
    end

    Rate.load_data(tmp_file_name)
  end
end

FileUtils.rm_r(dir)
