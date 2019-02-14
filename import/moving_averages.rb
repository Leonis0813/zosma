require 'csv'
require 'fileutils'
require 'logger'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../config/initialize'
require_relative '../db/connect'
require_relative '../models/moving_average'

BACKUP_DIR = File.join(APPLICATION_ROOT, Settings.import.file.moving_average.backup_dir)

logger = Logger.new(Settings.logger.path.import)
logger.formatter = proc do |severity, datetime, progname, message|
  time = datetime.utc.strftime(Settings.logger.time_format)
  log = "[#{severity}] [#{time}]: #{message}"
  puts log if ENV['STDOUT'] == 'on'
  "#{log}\n"
end

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
        :size => File.stat(tar_gz_file).size
      )
    else
      [
        Dir[File.join(BACKUP_DIR, "#{yearmonth}-*.csv")],
        Dir[File.join(Settings.import.file.moving_average.src_dir, "*_#{yearmonth}-*.csv")],
      ].each do |csv_files|
        FileUtils.cp(csv_files, dir)
        logger.info(
          :action => 'copy',
          :files => csv_files.map {|file| File.basename(file) },
        )
      end
    end
  end

  tmp_file_name = File.join(dir, 'moving_averages.csv')

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
        moving_averages = CSV.read(file)
        logger.info(
          :action => 'read',
          :file => File.basename(file),
          :size => File.stat(file).size
        )
        moving_averages.each {|moving_average| csv << moving_average }
      end

      headers = MovingAverage.attribute_names - %w[ id created_at updated_at ]
      ids = headers.size.times.map {|i| "@#{i + 1}" }
      variables = headers.map.with_index(1) {|header, i| "`#{header}`=@#{i}" }
      variables += %w[ created_at=now() updated_at=now() ]

      sql = <<"EOF"
LOAD DATA LOCAL INFILE '#{tmp_file_name}'
  INTO TABLE #{MovingAverage.table_name}
  FIELDS TERMINATED BY ',' (#{ids.join(',')}) SET #{variables.join(',')}
EOF

      moving_average_size = File.read(tmp_file_name).lines.size
      sql_start = Time.now
      ActiveRecord::Base.connection.execute(sql)
      logger.info(
        :action => 'load',
        :line => moving_average_size,
        :runtime => Time.now - sql_start
      )

      sql = "ALTER TABLE #{MovingAverage.table_name} AUTO_INCREMENT = #{moving_average_size + 1}"
      ActiveRecord::Base.connection.execute(sql)
    end

    backup_file = File.join(BACKUP_DIR, "#{date_string}.csv")
    unless File.exists?(backup_file) or
          File.exists?(File.join(BACKUP_DIR, "#{date.strftime('%Y-%m')}.tar.gz"))
      moving_averages = MovingAverage.where('DATE(`time`) = ?', date_string)
      unless moving_averages.empty?
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
            :action => 'backup',
            :file => File.basename(backup_file),
            :lines => moving_averages.size,
            :size => File.stat(backup_file).size
          )
        end
      end
    end
  end
end