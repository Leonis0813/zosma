require 'csv'
require 'fileutils'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../config/initialize'
require_relative '../db/connect'
require_relative '../lib/import_util'
require_relative '../lib/zosma_logger'
require_relative '../models/moving_average'

BACKUP_DIR = File.join(APPLICATION_ROOT, Settings.import.file.moving_average.backup_dir)
logger = ZosmaLogger.new(Settings.logger.path.import)

begin
  from = ARGV.find {|arg| arg.start_with?('--from=') }
  from = from ? Date.parse(from.match(/\A--from=(.*)\z/)[1]) : (Date.today - 2)
  to = ARGV.find {|arg| arg.start_with?('--to=') }
  to = to ? Date.parse(to.match(/\A--to=(.*)\z/)[1]) : (Date.today - 2)
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
    [
      Dir[File.join(BACKUP_DIR, "#{yearmonth}-*.csv")],
      Dir[File.join(Settings.import.file.moving_average.src_dir, "*_#{yearmonth}-*.csv")],
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

  target_files(dir, date_string).each do |file|
    CSV.open(tmp_file_name, 'w') do |csv|
      moving_averages = CSV.read(file)
      logger.info(action: 'read', file: File.basename(file), size: File.stat(file).size)
      moving_averages.each {|moving_average| csv << moving_average }
    end

    headers = MovingAverage.attribute_names - %w[id created_at updated_at]
    ids = headers.size.times.map {|i| "@#{i + 1}" }
    variables = headers.map.with_index(1) {|header, i| "`#{header}`=@#{i}" }
    variables += %w[created_at=now() updated_at=now()]
    load_data(tmp_file_name, ids, variables, MovingAverage.table_name)
  end

  backup_file = File.join(BACKUP_DIR, "#{date_string}.csv")
  next if File.exist?(backup_file) or
          File.exist?(File.join(BACKUP_DIR, "#{date.strftime('%Y-%m')}.tar.gz"))

  moving_averages = MovingAverage.where('DATE(`time`) = ?', date_string)
  next if moving_averages.empty?

  FileUtils.mkdir_p(BACKUP_DIR)

  CSV.open(backup_file, 'w') do |csv|
    moving_averages.each do |moving_average|
      csv << [
        moving_average.time.strftime('%F %T'),
        moving_average.pair,
        moving_average.time_frame,
        moving_average.period,
        moving_average.value,
      ]
    end

    logger.info(
      action: 'backup',
      file: File.basename(backup_file),
      lines: moving_averages.size,
      size: File.stat(backup_file).size,
    )
  end
end

FileUtils.rm_r(dir)
