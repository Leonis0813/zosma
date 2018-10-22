require 'csv'
require 'fileutils'
require 'logger'
require 'tmpdir'
require_relative '../config/initialize'
require_relative '../db/connect'
Dir['models/*'].each {|f| require_relative "../#{f}" }

TARGET_DATE = (Date.today - 2).strftime('%F')
TARGET_FILES = Dir[File.join(Settings.import.file.rate.src_dir, "*_#{TARGET_DATE}.csv")]
BACKUP_DIR = File.join(APPLICATION_ROOT, Settings.import.backup_dir)

logger = Logger.new(Settings.logger.path.import)
logger.formatter = proc do |severity, datetime, progname, message|
  time = datetime.utc.strftime(Settings.logger.time_format)
  log = "[#{severity}] [#{time}]: #{message}"
  puts log if ENV['STDOUT'] == 'on'
  "#{log}\n"
end

logger.info("==== Start importing rates (date: #{TARGET_DATE})")
start_time = Time.now

Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |dir|
  tmp_file_name = File.join(dir, 'rates.csv')

  TARGET_FILES.each do |file|
    CSV.open(tmp_file_name, 'w') do |csv|
      rates = CSV.read(file, :converters => :all).map do |rate|
        [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]]
      end
      logger.info(:action => 'read', :file => File.basename(file), :size => File.stat(file).size)
      before_size = rates.size
      rates.uniq! {|rate| [rate[0], rate[1]] }

      logger.info(:action => 'unique', :before_size => before_size, :after_size => rates.size)

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

    sql_start = Time.now
    ActiveRecord::Base.connection.execute(sql)
    logger.info(
      :action => 'load',
      :line => File.read(tmp_file_name).lines.size,
      :runtime => Time.now - sql_start
    )

    rate_size = CSV.read(tmp_file_name).size
    sql = "ALTER TABLE #{Rate.table_name} AUTO_INCREMENT = #{rate_size + 1}"
    ActiveRecord::Base.connection.execute(sql)
  end
end

rates = Rate.where('DATE(`time`) = ?', TARGET_DATE)
unless rates.empty?
  FileUtils.mkdir_p(BACKUP_DIR)

  backup_file = File.join(BACKUP_DIR, "#{TARGET_DATE}.csv")
  CSV.open(backup_file, 'w') do |csv|
    rates.each do |rate|
      csv << [rate.id, rate.time.strftime('%F %T'), rate.pair, rate.bid, rate.ask]
    end

    logger.info(
      :action => 'backup',
      :file => File.basename(backup_file),
      :lines => rates.size,
      :size => File.stat(backup_file).size
    )
  end
end

logger.info("==== Finish importing rates (run_time: #{Time.now - start_time})")
