require 'fileutils'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../config/initialize'
require_relative '../lib/zosma_logger'

TARGET_MONTH = (Date.today << 1).strftime('%Y-%m')
logger = ZosmaLogger.new(Settings.logger.path.compress)

logger.info("==== Start compressing (month: #{TARGET_MONTH})")
start_time = Time.now

%w[rate candle_stick].each do |type|
  Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |dir|
    export_dir = File.join(APPLICATION_ROOT, Settings.import.file[type].backup_dir)
    compressed_dir = File.join(dir, TARGET_MONTH)
    FileUtils.mkdir_p(compressed_dir)

    gzip_file = File.join(export_dir, "#{TARGET_MONTH}.tar.gz")
    Zlib::GzipWriter.open(gzip_file, Zlib::BEST_COMPRESSION) do |gzip|
      out = Minitar::Output.new(gzip)

      FileUtils.cp(Dir[File.join(export_dir, "#{TARGET_MONTH}-*.csv")], compressed_dir)
      Dir.chdir(dir)
      Dir["#{TARGET_MONTH}/*"].each do |file|
        Minitar.pack_file(file, out)
        logger.info(
          action: 'pack',
          csv_file: File.basename(file),
          lines: File.read(file).lines.size,
          size: File.stat(file).size,
        )
      end

      out.close
    end

    logger.info(
      action: 'compress',
      gzip_file: File.basename(gzip_file),
      size: File.stat(gzip_file).size,
    )
  end
end

logger.info("==== Finish compressing (run_time: #{Time.now - start_time})")
