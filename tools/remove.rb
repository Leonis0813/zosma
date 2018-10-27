require 'csv'
require 'fileutils'
require 'logger'
require_relative '../config/initialize'
require_relative '../db/connect'
Dir[File.join(APPLICATION_ROOT, 'models/*')].each {|f| require_relative f }

TARGET_DATE = (Date.today - 2).strftime('%F')
TARGET_FILES = Dir[File.join(Settings.import.src_dir, "*_#{TARGET_DATE}.csv")]

logger = Logger.new(Settings.logger.path.remove)
logger.formatter = proc do |severity, datetime, progname, message|
  time = datetime.utc.strftime(Settings.logger.time_format)
  log = "[#{severity}] [#{time}]: #{message}"
  puts log if ENV['STDOUT'] == 'on'
  "#{log}\n"
end

logger.info("==== Start removing (date: #{TARGET_DATE})")
start_time = Time.now

rates_file = TARGET_FILES.inject([]) do |rates, file|
  lines = CSV.read(file, :converters => :all)
  lines.each {|rate| rates << [rate[0].strftime('%F %T'), rate[1], rate[2], rate[3]] }
  logger.info(
    :action => 'read',
    :file => File.basename(file),
    :lines => lines.size,
    :size => File.stat(file).size
  )
  rates
end.uniq {|rate| [rate[0], rate[1]] }

rates_db = Rate.where('DATE(`time`) = ?', TARGET_DATE)
logger.info(
  :action => 'compare',
  :file_rate_size => rates_file.size,
  :db_rate_size => rates_db.size
)

if rates_file.size ==  rates_db.size
  FileUtils.rm(TARGET_FILES)
  logger.info(:action => 'remove', :removed_files => TARGET_FILES)
end

logger.info("==== Finish removing (run_time: #{Time.now - start_time})")