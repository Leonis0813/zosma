require 'csv'
require 'fileutils'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../config/initialize'
require_relative '../db/connect'
require_relative '../lib/zosma_logger'
require_relative '../models/candle_stick'

BACKUP_DIR = File.join(APPLICATION_ROOT, Settings.import.file.candle_stick.backup_dir)
logger = ZosmaLogger.new(Settings.logger.path.import)

begin
  from = ARGV.find {|arg| arg.start_with?('--from=') }
  from = from ? Date.parse(from.match(/\A--from=(.*)\z/)[1]) : (Date.today - 2)
  to = ARGV.find {|arg| arg.start_with?('--to=') }
  to = to ? Date.parse(to.match(/\A--to=(.*)\z/)[1]) : (Date.today - 2)
rescue Exception => e
  logger.error(e.backtrace.join("\n"))
  raise e
end

Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |dir|
  (from.strftime('%Y-%m')..to.strftime('%Y-%m')).each do |yearmonth|
    tar_gz_file = File.join(BACKUP_DIR, "#{yearmonth}.tar.gz")

    if File.exists?(tar_gz_file)
      Zlib::GzipReader.open(tar_gz_file) do |file|
        Archive::Tar::Minitar::unpack(file, dir)
      end
      FileUtils.mv(Dir[File.join(dir, yearmonth, '*')], dir)
      logger.info(
        :action => 'unpack',
        :file => File.basename(tar_gz_file),
        :size => File.stat(tar_gz_file).size,
      )
    else
      [
        Dir[File.join(BACKUP_DIR, "#{yearmonth}-*.csv")],
        Dir[File.join(Settings.import.file.candle_stick.src_dir, "*_#{yearmonth}-*.csv")],
      ].each do |csv_files|
        FileUtils.cp(csv_files, dir)
        logger.info(
          :action => 'copy',
          :files => csv_files.map {|file| File.basename(file) },
        )
      end
    end
  end

  tmp_file_name = File.join(dir, 'candle_sticks.csv')

  (from..to).each do |date|
    date_string = date.strftime('%F')
    csv_file = File.join(dir, "#{date_string}.csv")
    target_files = if File.exists?(csv_file)
                     [csv_file]
                   else
                     Dir[File.join(dir, "*_#{date_string}.csv")]
                   end

    target_files.each do |file|
      CSV.open(tmp_file_name, 'w') do |csv|
        candle_sticks = CSV.read(file)
        logger.info(
          :action => 'read',
          :file => File.basename(file),
          :size => File.stat(file).size,
        )
        candle_sticks.each {|candle_stick| csv << candle_stick }
      end

      headers = CandleStick.attribute_names - %w[ id created_at updated_at ]
      ids = headers.size.times.map {|i| "@#{i + 1}" }
      variables = headers.map.with_index(1) {|header, i| "`#{header}`=@#{i}" }
      variables += %w[ created_at=now() updated_at=now() ]

      sql = <<"EOF"
LOAD DATA LOCAL INFILE '#{tmp_file_name}'
  INTO TABLE #{CandleStick.table_name}
  FIELDS TERMINATED BY ',' (#{ids.join(',')}) SET #{variables.join(',')}
EOF

      candle_stick_size = File.read(tmp_file_name).lines.size
      sql_start = Time.now
      ActiveRecord::Base.connection.execute(sql)
      logger.info(
        :action => 'load',
        :line => candle_stick_size,
        :runtime => Time.now - sql_start,
      )

      sql = "ALTER TABLE #{CandleStick.table_name} AUTO_INCREMENT = #{candle_stick_size + 1}"
      ActiveRecord::Base.connection.execute(sql)
    end

    backup_file = File.join(BACKUP_DIR, "#{date_string}.csv")
    unless File.exists?(backup_file) or
          File.exists?(File.join(BACKUP_DIR, "#{date.strftime('%Y-%m')}.tar.gz"))
      candle_sticks = CandleStick.where('DATE(`to`) = ?', date_string)
      unless candle_sticks.empty?
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

          logger.info(
            :action => 'backup',
            :file => File.basename(backup_file),
            :lines => candle_sticks.size,
            :size => File.stat(backup_file).size,
          )
        end
      end
    end
  end
end
