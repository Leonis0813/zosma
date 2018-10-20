require 'csv'
require 'fileutils'
require 'logger'
require 'tmpdir'
require_relative 'config/initialize'
require_relative 'db/connect'
Dir['models/*'].each {|f| require_relative f }

TARGET_DATE = (Date.today - 2).strftime('%F')
TARGET_FILES = Dir[File.join(Settings.import.file.candle_stick.src_dir, "*_#{TARGET_DATE}.csv")]
BACKUP_DIR = File.join(APPLICATION_ROOT, Settings.import.backup_dir, 'candle_sticks')

logger = Logger.new(Settings.logger.path.import)
logger.formatter = proc do |severity, datetime, progname, message|
  time = datetime.utc.strftime(Settings.logger.time_format)
  log = "[#{severity}] [#{time}]: #{message}"
  puts log if ENV['STDOUT'] == 'on'
  "#{log}\n"
end

logger.info("==== Start importing candle sticks (date: #{TARGET_DATE})")
start_time = Time.now

Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |dir|
  tmp_file_name = File.join(dir, 'candle_sticks.csv')

  TARGET_FILES.each do |file|
    CSV.open(tmp_file_name, 'w') do |csv|
      candle_sticks = CSV.read(file)
      logger.info(:action => 'read', :file => File.basename(file), :size => File.stat(file).size)
      candle_sticks.each {|candle_stick| csv << candle_stick }
    end

    headers = Settings.import.file.candle_stick.headers
    ids = headers.size.times.map {|i| "@#{i + 1}" }
    variables = headers.map.with_index(1) {|header, i| "#{header}=@#{i}" }
    variables += %w[ created_at=now() updated_at=now() ]

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

candle_sticks = Rate.where('DATE(`time`) = ?', TARGET_DATE)
unless candle_sticks.empty?
  FileUtils.mkdir_p(BACKUP_DIR)

  backup_file = File.join(BACKUP_DIR, "#{TARGET_DATE}_candle_sticks.csv")
  CSV.open(backup_file, 'w') do |csv|
    candle_sticks.each do |rate|
      csv << [rate.id, rate.time.strftime('%F %T'), rate.pair, rate.bid, rate.ask]
    end

    logger.info(
      :action => 'backup',
      :file => File.basename(backup_file),
      :lines => candle_sticks.size,
      :size => File.stat(backup_file).size
    )
  end
end

logger.info("==== Finish importing candle sticks (run_time: #{Time.now - start_time})")
