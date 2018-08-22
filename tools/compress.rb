require 'fileutils'
require 'logger'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../config/initialize'

TARGET_MONTH = (Date.today << 1).strftime('%Y-%m')
EXPORT_DIR = File.join(APPLICATION_ROOT, Settings.import.backup_dir)

logger = Logger.new(Settings.logger.path.compress)
logger.formatter = proc do |severity, datetime, progname, message|
  time = datetime.utc.strftime(Settings.logger.time_format)
  log = "[#{severity}] [#{time}]: #{message}"
  puts log if ENV['STDOUT'] == 'on'
  "#{log}\n"
end

logger.info("==== Start compressing (month: #{TARGET_MONTH})")
start_time = Time.now

Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |dir|
  compressed_dir = File.join(dir, TARGET_MONTH)
  FileUtils.mkdir_p(compressed_dir)

  gzip_file = File.join(EXPORT_DIR, "#{TARGET_MONTH}.tar.gz")
  Zlib::GzipWriter.open(gzip_file, Zlib::BEST_COMPRESSION) do |gzip|
    out = Minitar::Output.new(gzip)

    FileUtils.cp(Dir[File.join(EXPORT_DIR, "#{TARGET_MONTH}-*.csv")], compressed_dir)
    Dir.chdir(dir)
    Dir["#{TARGET_MONTH}/*"].each do |file|
      Minitar::pack_file(file, out)
      logger.info(
        :action => 'pack',
        :csv_file => File.basename(file),
        :lines => File.read(file).lines.size,
        :size => File.stat(file).size,
      )
    end

    out.close
  end

  logger.info(
    :action => 'compress',
    :gzip_file => File.basename(gzip_file),
    :size => File.stat(gzip_file).size
  )
end

logger.info("==== Finish compressing (run_time: #{Time.now - start_time})")
