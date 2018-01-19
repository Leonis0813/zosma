require 'fileutils'
require 'minitar'
require 'zlib'
require_relative 'logger'
require_relative '../config/settings'

TARGET_MONTH = (Date.today << 1).strftime('%Y-%m')
TMP_DIR = File.join(Settings.application_root, 'tmp')
COMPRESSED_DIR = File.join(TMP_DIR, TARGET_MONTH)
EXPORT_DIR = File.join(Settings.application_root, 'backup')
COMPRESSED_FILES = Dir[File.join(EXPORT_DIR, "#{TARGET_MONTH}-*.csv")]
GZIP_FILE = "#{TARGET_MONTH}.tar.gz"

FileUtils.mkdir_p(COMPRESSED_DIR)

Logger.write_with_runtime(:module => 'compress', :gzip_file => GZIP_FILE) do
  Zlib::GzipWriter.open(File.join(EXPORT_DIR, GZIP_FILE), Zlib::BEST_COMPRESSION) do |gz|
    out = Minitar::Output.new(gz)

    FileUtils.cp(COMPRESSED_FILES, COMPRESSED_DIR)
    Dir.chdir(TMP_DIR)
    Dir["#{TARGET_MONTH}/*"].each do |file|
      Logger.write_with_runtime(:compressed_file => File.basename(file)) do
        Minitar::pack_file(file, out)
      end
    end

    out.close
  end
end

FileUtils.rm_rf(COMPRESSED_DIR)
