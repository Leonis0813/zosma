require 'fileutils'
require 'logger'
require 'minitar'
require 'tmpdir'
require 'zlib'
require_relative '../config/initialize'

TARGET_MONTH = (Date.today << 1).strftime('%Y-%m')
EXPORT_DIR = File.join(APPLICATION_ROOT, Settings.import.backup_dir)

Dir.mktmpdir(nil, File.join(APPLICATION_ROOT, Settings.import.tmp_dir)) do |dir|
  compressed_dir = File.join(dir, TARGET_MONTH)
  FileUtils.mkdir_p(compressed_dir)

  gzip_file = File.join(EXPORT_DIR, "#{TARGET_MONTH}.tar.gz")
  Zlib::GzipWriter.open(gzip_file, Zlib::BEST_COMPRESSION) do |gzip|
    out = Minitar::Output.new(gzip)

    FileUtils.cp(Dir[File.join(EXPORT_DIR, "#{TARGET_MONTH}-*.csv")], compressed_dir)
    Dir.chdir(dir)
    Dir["#{TARGET_MONTH}/*"].each {|file| Minitar::pack_file(file, out) }

    out.close
  end
end
