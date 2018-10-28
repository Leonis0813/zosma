require 'csv'
require 'fileutils'
require 'logger'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../config/initialize'
require_relative '../db/connect'
Dir['models/*'].each {|f| require_relative "../#{f}" }

BACKUP_DIR = File.join(APPLICATION_ROOT, Settings.import.file.rate.backup_dir)

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
    csv_files = Dir[File.join(BACKUP_DIR, "#{yearmonth}-*.csv")]

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
    elsif not csv_files.empty?
      FileUtils.cp(csv_files, dir)
      logger.info(:action => 'copy', :files => csv_files)
    else
      csv_files = File.join(Settings.import.file.rate.src_dir, "*_#{yearmonth}-*.csv")
      FileUtils.cp(Dir[csv_files], dir)
      logger.info(:action => 'copy', :files => csv_files)
    end
  end

  tmp_file_name = File.join(dir, 'rates.csv')

  (from..to).each do |date|
    date_string = date.strftime('%F')
    csv_file = File.join(dir, "#{date_string}.csv")
    target_files = if File.exists?(csv_file)
                     [csv_file]
                   else
                     Dir[File.join(dir, "*_#{date_string}.csv")]
                   end

    target_files.each do |csv_file|
      CSV.open(tmp_file_name, 'w') do |csv|
        rates = CSV.read(csv_file, :converters => :all).map do |rate|
          [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]]
        end
        logger.info(
          :action => 'read',
          :file => File.basename(csv_file),
          :size => File.stat(csv_file).size
        )

        before_size = rates.size
        rates.uniq! {|rate| [rate[0], rate[1]] }
        logger.info(
          :action => 'unique',
          :before_size => before_size,
          :after_size => rates.size
        )

        rates.each {|rate| csv << rate }
      end

      headers = Settings.import.file.rate.headers
      ids = headers.size.times.map {|i| "@#{i + 1}" }
      variables = headers.map.with_index(1) {|header, i| "#{header}=@#{i}" }

      sql = <<"EOF"
LOAD DATA LOCAL INFILE '#{tmp_file_name}'
  INTO TABLE #{Rate.table_name}
  FIELDS TERMINATED BY ',' (#{ids.join(',')}) SET #{variables.join(',')}
EOF

      rate_size = File.read(tmp_file_name).lines.size
      sql_start = Time.now
      ActiveRecord::Base.connection.execute(sql)
      logger.info(
        :action => 'load',
        :line => rate_size,
        :runtime => Time.now - sql_start
      )

      sql = "ALTER TABLE #{Rate.table_name} AUTO_INCREMENT = #{rate_size + 1}"
      ActiveRecord::Base.connection.execute(sql)
    end

    backup_file = File.join(BACKUP_DIR, "#{date_string}.csv")
    unless File.exists?(backup_file)
      rates = Rate.where('DATE(`time`) = ?', date_string)
      unless rates.empty?
        FileUtils.mkdir_p(BACKUP_DIR)

        CSV.open(backup_file, 'w') do |csv|
          rates.each do |rate|
            csv << [rate.time.strftime('%F %T'), rate.pair, rate.bid, rate.ask]
          end

          logger.info(
            :action => 'backup',
            :file => File.basename(backup_file),
            :lines => rates.size,
            :size => File.stat(backup_file).size
          )
        end
      end
    end
  end
end
