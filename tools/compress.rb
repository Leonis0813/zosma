require_relative '../config/initialize'
require_relative '../lib/zip_util'

TARGET_MONTH = (Date.today << 1).strftime('%Y-%m')
logger = ZosmaLogger.new(Settings.logger.path.compress)

logger.info('======== Start Compress ========')
logger.info("Month: #{TARGET_MONTH}")

%w[rate candle_stick].each do |type|
  logger.info("==== Compress #{type}")

  Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |dir|
    export_dir = File.join(APPLICATION_ROOT, Settings.import.file[type].backup_dir)
    compressed_dir = File.join(dir, TARGET_MONTH)
    FileUtils.mkdir_p(compressed_dir)

    target_files = Dir[File.join(export_dir, "#{TARGET_MONTH}-*.csv")]
    FileUtils.cp(target_files, compressed_dir)
    logger.info("Target Files: #{target_files}")

    gzip_file = File.join(export_dir, "#{TARGET_MONTH}.tar.gz")
    ZipUtil.write(gzip_file, dir, File.join(TARGET_MONTH, '*'))
    logger.info("Create #{gzip_file} (#{File.stat(gzip_file).size} bytes)")
  end
end

logger.info('====')
logger.info('======== Finish Compress ========')
