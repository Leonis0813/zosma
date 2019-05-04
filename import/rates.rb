require 'csv'
require 'fileutils'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../config/initialize'
require_relative '../db/connect'
require_relative '../lib/zosma_logger'
require_relative '../models/rate'

BACKUP_DIR = File.join(APPLICATION_ROOT, Settings.import.file.rate.backup_dir)
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

Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |dir|
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
    csv_file = File.join(dir, "#{date_string}.csv")
    target_files = if File.exist?(csv_file)
                     [csv_file]
                   else
                     Dir[File.join(dir, "*_#{date_string}.csv")]
                   end

    target_files.each do |target_file|
      CSV.open(tmp_file_name, 'w') do |csv|
        rates = CSV.read(target_file, converters: :all).map do |rate|
          [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]]
        end
        logger.info(
          action: 'read',
          file: File.basename(target_file),
          size: File.stat(target_file).size,
        )

        before_size = rates.size
        rates.uniq! {|rate| [rate[0], rate[1]] }
        logger.info(
          action: 'unique',
          before_size: before_size,
          after_size: rates.size,
        )

        rates.each {|rate| csv << rate }
      end

      headers = Rate.attribute_names - %w[id created_at updated_at]
      ids = headers.size.times.map {|i| "@#{i + 1}" }
      variables = headers.map.with_index(1) {|header, i| "#{header}=@#{i}" }
      variables += %w[created_at=now() updated_at=now()]

      sql = <<~"SQL"
        LOAD DATA LOCAL INFILE '#{tmp_file_name}'
        INTO TABLE #{Rate.table_name}
        FIELDS TERMINATED BY ',' (#{ids.join(',')}) SET #{variables.join(',')}
      SQL

      rate_size = File.read(tmp_file_name).lines.size
      sql_start = Time.now
      ActiveRecord::Base.connection.execute(sql)
      logger.info(
        action: 'load',
        line: rate_size,
        runtime: Time.now - sql_start,
      )

      sql = "ALTER TABLE #{Rate.table_name} AUTO_INCREMENT = #{rate_size + 1}"
      ActiveRecord::Base.connection.execute(sql)
    end

    backup_file = File.join(BACKUP_DIR, "#{date_string}.csv")
    next if File.exist?(backup_file) or
            File.exist?(File.join(BACKUP_DIR, "#{date.strftime('%Y-%m')}.tar.gz"))

    rates = Rate.where('DATE(`time`) = ?', date_string)
    next if rates.empty?

    FileUtils.mkdir_p(BACKUP_DIR)

    CSV.open(backup_file, 'w') do |csv|
      rates.each do |rate|
        csv << [rate.time.strftime('%F %T'), rate.pair, rate.bid, rate.ask]
      end

      logger.info(
        action: 'backup',
        file: File.basename(backup_file),
        lines: rates.size,
        size: File.stat(backup_file).size,
      )
    end
  end
end
